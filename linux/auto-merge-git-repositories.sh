#!/bin/bash

# 設定A repo和B repo的URL（如果使用本地目錄，則不需要）
AREPO_URL="A_repo的URL"
BREPO_URL="B_repo的URL"

# 設定A repo和B repo的分支名稱
AREPO_BRANCH="master"
BREPO_BRANCH="main"

# 設定A repo和B repo的本地目錄位置（如果使用URL，則不需要）
AREPO_DIR="" # 例如："/path/to/arepo"
BREPO_DIR="" # 例如："/path/to/brepo"

# 檢查變數設定
if [[ -n "$AREPO_DIR" && -n "$BREPO_DIR" ]]; then
    USE_LOCAL="true"
elif [[ -z "$AREPO_URL" || -z "$BREPO_URL" ]]; then
    echo "錯誤：必須設定AREPO_URL和BREPO_URL，或者設定AREPO_DIR和BREPO_DIR。"
    exit 1
fi

# 使用本地目錄進行操作
if [ "$USE_LOCAL" = "true" ]; then
    # 切換到A repo目錄
    cd "$AREPO_DIR" || exit
    # 確保A repo目錄是一個git倉庫
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "錯誤：A repo目錄不是一個有效的Git倉庫。"
        exit 1
    fi

    # 將B repo目錄添加為遠端
    git remote add brepo "$BREPO_DIR"
    # 拉取B repo數據（僅在需要時執行）
    git fetch brepo

    # 從B repo合併到A repo
    git merge brepo/$BREPO_BRANCH --allow-unrelated-histories
else
    # 使用URL克隆A repo到臨時目錄並操作
    TEMP_DIR=$(mktemp -d)
    git clone $AREPO_URL $TEMP_DIR
    cd $TEMP_DIR

    git remote add brepo $BREPO_URL
    git fetch brepo

    git checkout $AREPO_BRANCH
    git merge brepo/$BREPO_BRANCH --allow-unrelated-histories
fi

# 檢查合併衝突
CONFLICTS=$(git ls-files -u | wc -l)
if [ "$CONFLICTS" -gt 0 ]; then
    echo "存在合併衝突。請手動解決衝突，然後運行 'git commit' 來完成合併。"
else
    echo "合併成功，沒有衝突。"
    # 如果沒有衝突，自動推送到A repo的指定分支
    git push origin $AREPO_BRANCH
    echo "更改已經被推送到 $AREPO_BRANCH 分支。"
fi

# 如果是使用URL進行操作，提供臨時目錄的資訊
if [ -z "$USE_LOCAL" ]; then
    echo "請檢查合併結果。如果一切正常，請手動推送到遠端：'git push origin $AREPO_BRANCH'。"
    echo "A repo已經被複製到臨時目錄：$TEMP_DIR。請在完成操作後手動刪除此目錄。"
fi

