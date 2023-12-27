#!/bin/bash

set -e  # 如果任何命令失敗則退出腳本

# 設定集群名稱和區域變數
CLUSTER_NAMES=$(aws eks list-clusters --query "clusters[]" --output text)
export CLUSTER_NAME=$(echo "$CLUSTER_NAMES" | grep "$CLUSTER_NAME_ENV" | cut -d$'\t' -f1)

if [ -z "$CLUSTER_NAME" ]; then
    echo "沒有找到與'$CLUSTER_NAME_PATTERN'匹配的集群。"
    exit 1
fi

# 獲取OIDC提供者URL
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER_HOST=$(echo $OIDC_PROVIDER_URL | awk -F'https://' '{print $2}')

# 檢查OIDC身份提供者是否存在，並刪除
if aws iam list-open-id-connect-providers | grep -q "$OIDC_PROVIDER_HOST"; then
    PROVIDER_ARN=$(aws iam list-open-id-connect-providers | grep "$OIDC_PROVIDER_HOST" | awk '{print $3}')
    echo "正在刪除OIDC身份提供者：$PROVIDER_ARN"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER_ARN"
    echo "已刪除OIDC身份提供者：$PROVIDER_ARN"
else
    echo "未找到OIDC身份提供者：$OIDC_PROVIDER_HOST"
fi
