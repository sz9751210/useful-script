#!/bin/bash

# 定義來源和目的地資訊
SOURCE_USER=""
SOURCE_IP=""

DEST_USER=""
DEST_IP=""

DIR="path"

# 詢問使用者模式
echo "請選擇模式: push 或 pull"
read MODE

if [ "$MODE" == "push" ]; then
    # 如果選擇的是 push，從本地同步到遠端
    echo "正在執行 push 模式，將 $DIR 從本機 ($SOURCE_USER@$SOURCE_IP) 同步到遠端 ($DEST_USER@$DEST_IP)..."
    rsync -avz -e ssh $DIR $DEST_USER@$DEST_IP:$DIR
elif [ "$MODE" == "pull" ]; then
    # 如果選擇的是 pull，從遠端同步到本地
    echo "正在執行 pull 模式，將 $DIR 從遠端 ($SOURCE_USER@$SOURCE_IP) 同步到本機..."
    rsync -avz -e ssh $SOURCE_USER@$SOURCE_IP:$DIR $DIR
else
    echo "未知模式: $MODE"
    exit 1
fi

# 說明：
# -a (archive) 代表存檔模式，保留檔案權限、時間戳等資訊
# -v (verbose) 代表顯示詳細的傳輸資訊
# -z (compress) 代表在傳輸過程中進行資料壓縮，以減少網絡使用量
# -e ssh 指定使用 SSH 作為資料傳輸的通道，增加傳輸安全性
