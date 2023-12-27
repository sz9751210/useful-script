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

# 刪除AWS Load Balancer控制器
helm delete aws-load-balancer-controller -n kube-system

# 刪除IAM策略和角色
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
aws iam detach-role-policy --role-name "$CLUSTER_NAME-AmazonEKSLoadBalancerControllerRole" --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"
aws iam delete-role --role-name "$CLUSTER_NAME-AmazonEKSLoadBalancerControllerRole"
aws iam delete-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

# 刪除自動擴展相關的IAM角色和策略
aws iam detach-role-policy --role-name cluster-autoscaler --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/k8s-cluster-autoscaler-asg-policy"
aws iam delete-role --role-name $CLUSTER_NAME-cluster-autoscaler
aws iam delete-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/k8s-cluster-autoscaler-asg-policy"

# 刪除自動擴展部署
kubectl delete -f files/asg.yaml

# 從 Helm 移除 EKS 存儲庫
helm repo remove eks
