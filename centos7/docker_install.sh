#!/bin/bash

# 更新系統
sudo yum update -y

# 安裝需要的包
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# 添加 Docker 的官方 YUM 倉庫
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安裝 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 啟動 Docker 並設置為開機自啟
sudo systemctl start docker
sudo systemctl enable docker

# 添加當前用戶到 docker 組（可選）
sudo usermod -aG docker $(whoami)

# 安裝 Docker Compose
# 注意：請檢查 https://github.com/docker/compose/releases 以獲取最新版本
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 輸出版本以確認安裝成功
docker --version
docker-compose --version
