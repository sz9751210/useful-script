#!/bin/bash

# 檢查 jq 是否安裝
if ! command -v jq &> /dev/null; then
    echo '錯誤：jq 未安裝。請從 https://stedolan.github.io/jq/download/ 安裝。'
    exit 1
fi

# 定義查詢 IP 信息的函數
query_ip_info() {
    local ip=$1
    local link="http://ip-api.com/json/$ip"

    if ! data=$(curl -s "$link"); then
        echo "錯誤：無法從 $link 獲取數據。"
        return 1
    fi

    local status=$(echo "$data" | jq -r '.status')
    if [[ $status == "success" ]]; then
        local city=$(echo "$data" | jq -r '.city')
        local regionName=$(echo "$data" | jq -r '.regionName')
        local country=$(echo "$data" | jq -r '.country')
        local timezone=$(echo "$data" | jq -r '.timezone')
        echo "查詢 IP: $ip"
        echo "位置: $city, $regionName, $country"
        echo "時區: $timezone"
    else
        echo "錯誤：無法查詢 IP 地址信息。"
    fi
}

# 主程序
echo "選擇查詢方式："
echo "1. 使用本機 IP"
echo "2. 輸入 IP 地址"
read -r -p "請選擇 (1/2): " choice

case $choice in
    1)
        # 使用本機 IP
        my_ip=$(curl -s http://httpbin.org/ip | jq -r '.origin')
        query_ip_info "$my_ip"
        ;;
    2)
        # 提示用戶輸入 IP 地址
        read -r -p "請輸入 IP 地址: " user_ip
        query_ip_info "$user_ip"
        ;;
    *)
        echo "無效選擇。"
        exit 1
        ;;
esac
