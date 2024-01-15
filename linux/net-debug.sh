#!/bin/bash

# 獲取所有運行中的 Docker 容器名稱和容器ID
containers=$(docker ps --format '{{.Names}}')

# 檢查是否有容器運行
if [ -z "$containers" ]; then
    echo "沒有運行中的容器。"
    exit 1
fi

# 使用 select 讓使用者選擇一個容器
echo "請選擇一個容器："
select container in $containers; do
    if [ -n "$container" ]; then
        # 分割選擇的容器名稱和容器ID
        container_name=$(echo $container | awk '{print $1}')
        echo "你選擇的容器名稱是：$container_name"
        break
    else
        echo "無效的選擇。"
    fi
done

docker run -it --net container:$container_name nicolaka/netshoot
