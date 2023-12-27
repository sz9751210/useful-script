#!/bin/bash

set -e  # 如果任何命令失敗則退出腳本

# 函數：等待 EFS 文件系統可用
wait_for_efs() {
    local fs_id=$1
    local max_retries=30  # 最大重試次數
    local sleep_duration=10  # 每次重試的等待時間（秒）

    echo "正在等待 EFS 文件系統 $fs_id 可用..."
    for ((i=1; i<=max_retries; i++)); do
        if aws efs describe-file-systems --file-system-id "$fs_id" --query "FileSystems[?LifeCycleState=='available'].FileSystemId" --output text | grep -q "$fs_id"; then
            echo "EFS 文件系統 $fs_id 現在可用。"
            return 0
        else
            echo "等待中...（嘗試 $i 次）"
            sleep "$sleep_duration"
        fi
    done

    echo "超時:EFS 文件系統 $fs_id 未在預期時間內變為可用。"
    return 1
}

# 設定集群名稱和區域變數
CLUSTER_NAMES=$(aws eks list-clusters --query "clusters[]" --output text)
export CLUSTER_NAME=$(echo "$CLUSTER_NAMES" | grep "$CLUSTER_NAME_ENV" | cut -d$'\t' -f1)

if [ -z "$CLUSTER_NAME" ]; then
    echo "沒有找到與'$CLUSTER_NAME_ENV'匹配的集群。"
    exit 1
fi

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# 獲取OIDC提供者URL並提取主機名
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)
export OIDC_PROVIDER_HOST=$(echo $OIDC_PROVIDER_URL | awk -F'https://' '{print $2}')

# 創建 EFS 文件系統
export EFS_FILE_SYSTEM_ID=$(aws efs create-file-system --region "$REGION" --creation-token $CLUSTER_NAME --tags Key=Name,Value="$EFS_NAME" --performance-mode generalPurpose --throughput-mode bursting --encrypted --query 'FileSystemId' --output text)

wait_for_efs "$EFS_FILE_SYSTEM_ID"

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$CLUSTER_NAME-cluster-control-plane-sg" --query "SecurityGroups[*].GroupId" --output text)

if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "未找到名稱為 'eks-control-plane-sg' 的安全組。"
    exit 1
fi

# 配置安全組
aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 2049 --cidr "0.0.0.0/0"

# 創建掛載目標
for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text); do
    aws efs create-mount-target --file-system-id "$EFS_FILE_SYSTEM_ID" --subnet-id $subnet --security-groups "$SECURITY_GROUP_ID"
done

# 配置 IAM 和 OIDC
ROLE_NAME="$CLUSTER_NAME-AmazonEKS_EFS_CSI_DriverRole"

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://files/efs_trust_policy.json
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy

# 更新 kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# 創建 Kubernetes 服務賬戶並關聯至 IAM 角色
kubectl create serviceaccount -n kube-system efs-csi-controller-sa
kubectl annotate serviceaccount -n kube-system efs-csi-controller-sa eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME

kubectl create serviceaccount -n kube-system efs-csi-node-sa
kubectl annotate serviceaccount -n kube-system efs-csi-node-sa eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME

# 添加 AWS EFS CSI 驅動程式庫至 Helm
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update

# 使用自定義服務賬戶安裝 AWS EFS CSI 驅動程式
helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa \
    --set node.serviceAccount.create=false \
    --set node.serviceAccount.name=efs-csi-node-sa

# 創建 Kubernetes 存儲類別 (Storage Class) 用於 EFS
envsubst < sc.yaml | kubectl apply -f -

echo "EFS 文件系統 $EFS_FILE_SYSTEM_ID 已設置並連接至 EKS 集群 $CLUSTER_NAME 在 VPC $VPC_ID 中。"
