#!/bin/bash

set -e  # 如果任何命令失敗則退出腳本

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

# 為AWS Load Balancer控制器創建IAM策略
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://files/alb_policy.json --query 'Policy.Arn' --output text)

# 創建具有正確信任關係的AWS Load Balancer控制器的IAM角色
export IAM_ROLE_NAME="$CLUSTER_NAME-AmazonEKSLoadBalancerControllerRole"

envsubst < files/alb_trust_policy.json | aws iam create-role --role-name "$IAM_ROLE_NAME" --assume-role-policy-document file://files/alb_trust_policy.json.json

# 將策略附加到角色
aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" --policy-arn "$POLICY_ARN"

# 更新kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# 驗證VPC和安全組
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME_PATTERN" --query "Vpcs[*].VpcId" --output text)
if [ -z "$VPC_ID" ]; then
    echo "未找到名稱模式為'$VPC_NAME_PATTERN'的VPC。"
    exit 1
fi

# 創建服務帳戶
envsubst < sa.yaml | kubectl apply -f -

# 向 Helm 添加 EKS 存儲庫
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 安裝AWS Load Balancer控制器
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --set clusterName="$CLUSTER_NAME" \
    --set serviceAccount.create=false \
    --set region="$REGION" \
    --set vpcId="$VPC_ID" \
    --set serviceAccount.name=aws-load-balancer-controller \
    -n kube-system

# Create IAM policy
envsubst < files/asg_policy.json | aws iam create-policy --policy-name k8s-cluster-autoscaler-asg-policy --policy-document file://files/asg_policy.json

# Create IAM role with the correct trust relationship
envsubst < files/asg_trust_policy.json | aws iam create-role --role-name $CLUSTER_NAME-cluster-autoscaler --assume-role-policy-document file://files/asg_trust_policy.json

# # Attach policy to the role
aws iam attach-role-policy --role-name cluster-autoscaler --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/k8s-cluster-autoscaler-asg-policy

envsubst < asg.yaml | kubectl apply -f -
