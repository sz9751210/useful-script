#!/bin/bash

# 讀取環境變量檔案
source git_env.env

# 安裝 Git
sudo yum update -y
sudo yum install -y git

# 配置 Git 使用者名稱和電子郵件
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

# 確認配置
git config --list
