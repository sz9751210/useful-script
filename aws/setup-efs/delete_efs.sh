#!/bin/bash

set -e  # 如果任何命令失敗則退出腳本

# 獲取集群名稱
CLUSTER_NAMES=$(aws eks list-clusters --query "clusters[]" --output text)
export CLUSTER_NAME=$(echo "$CLUSTER_NAMES" | grep "$CLUSTER_NAME_ENV" | cut -d$'\t' -f1)

if [ -z "$CLUSTER_NAME" ]; then
    echo "沒有找到與'$CLUSTER_NAME_ENV'匹配的集群。"
    exit 1
fi

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# 設定EFS文件系統ID，根據您的環境，這可能需要修改
# 透過 EFS 名稱獲取 EFS 文件系統 ID
export EFS_FILE_SYSTEM_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='$EFS_NAME_ENV'].FileSystemId" --output text)

# 刪除 Kubernetes 存儲類別 (Storage Class)
kubectl delete -f files/sc.yaml

# 移除 AWS EFS CSI 驅動程式
helm uninstall aws-efs-csi-driver --namespace kube-system

# 刪除 Kubernetes 服務賬戶
kubectl delete serviceaccount -n kube-system efs-csi-controller-sa
kubectl delete serviceaccount -n kube-system efs-csi-node-sa

# 移除 IAM 和 OIDC
ROLE_NAME="$CLUSTER_NAME-AmazonEKS_EFS_CSI_DriverRole"
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy
aws iam delete-role --role-name $ROLE_NAME

# 刪除掛載目標
for mount_target in $(aws efs describe-mount-targets --file-system-id "$EFS_FILE_SYSTEM_ID" --query "MountTargets[*].MountTargetId" --output text); do
    aws efs delete-mount-target --mount-target-id $mount_target
done

# 等待所有掛載目標被刪除
while : ; do
   MT_COUNT=$(aws efs describe-mount-targets --file-system-id "$EFS_FILE_SYSTEM_ID" --query "MountTargets[*].MountTargetId" --output text | wc -w)
   if [ "$MT_COUNT" -eq 0 ]; then
      echo "所有掛載目標已刪除"
      break
   else
      echo "等待掛載目標刪除..."
      sleep 10
   fi
done

# 刪除 EFS 文件系統
aws efs delete-file-system --file-system-id "$EFS_FILE_SYSTEM_ID"

echo "EFS 文件系統 $EFS_FILE_SYSTEM_ID 及相關資源已從 EKS 集群 $CLUSTER_NAME 刪除。"
