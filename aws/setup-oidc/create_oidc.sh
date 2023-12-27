#!/bin/bash

set -e  # 如果任何命令失敗則退出腳本

# 設定集群名稱和區域變數
CLUSTER_NAMES=$(aws eks list-clusters --query "clusters[]" --output text)
export CLUSTER_NAME=$(echo "$CLUSTER_NAMES" | grep "$CLUSTER_NAME_ENV" | cut -d$'\t' -f1)
if [ -z "$CLUSTER_NAME" ]; then
    echo "沒有找到與'$CLUSTER_NAME_PATTERN'匹配的集群。"
    exit 1
fi

# 獲取OIDC提供者URL並提取主機名
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER_SERVER=$(echo $OIDC_PROVIDER_URL | awk -F/ '{print $3}')
OIDC_PROVIDER_HOST=$(echo $OIDC_PROVIDER_URL | awk -F'https://' '{print $2}')

# 獲取證書並提取指紋
CERT=$(echo | openssl s_client -servername $OIDC_PROVIDER_SERVER -showcerts -connect $OIDC_PROVIDER_SERVER:443 2>/dev/null)
if [ -z "$CERT" ]; then
    echo "Failed to fetch certificate from $OIDC_PROVIDER_SERVER"
    exit 1
fi

THUMBPRINT=$(echo "$CERT" | openssl x509 -fingerprint -noout -sha1 | awk -F= '{print $2}' | tr -d ':' | tr '[:upper:]' '[:lower:]')

echo "指紋：$THUMBPRINT"
if [ -z "$THUMBPRINT" ]; then
    echo "無法從$OIDC_PROVIDER_HOST獲取證書或提取指紋"
    exit 1
else
    echo "指紋：$THUMBPRINT"
fi

# 如果不存在，則為集群創建OIDC身份提供者
if ! aws iam list-open-id-connect-providers | grep -q "$OIDC_PROVIDER_HOST"; then
    aws iam create-open-id-connect-provider --url "$OIDC_PROVIDER_URL" --client-id-list sts.amazonaws.com --thumbprint-list "$THUMBPRINT"
fi
