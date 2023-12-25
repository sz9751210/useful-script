#!/bin/bash

# 腳本將以下功能添加到 ~/.bashrc
BASHRC=~/.bashrc

# 檢查 ~/.bashrc 文件是否存在
if [ ! -f "$BASHRC" ]; then
    echo "找不到 .bashrc 文件，正在創建..."
    touch "$BASHRC"
fi

# 添加 Git 提示符功能
echo '
# 獲取當前 Git 分支名稱和狀態
git_prompt() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return 0
    fi

    git_branch=$(git branch 2>/dev/null | sed -n "/^\*/s/^\* //p")
    if [ -n "$git_branch" ]; then
        if git diff --quiet 2>/dev/null >&2; then
            git_status="($git_branch)"
        else
            git_status="($git_branch*)"
        fi
    fi
    echo "$git_status"
}

# 定義 Bash 提示符
export PS1="\[\e[1;33m\]\w\[\e[m\] \[\e[1;32m\]\$(git_prompt)\[\e[m\]\$ "
' >> $BASHRC

# 添加一些有用的別名
echo '
# 常用別名
alias ll="ls -lAh"
alias grep="grep --color=auto"
alias df="df -h"
alias free="free -m"
' >> $BASHRC

# 添加命令執行時間提示
echo '
# 顯示上一個命令的執行時間
export PROMPT_COMMAND="RETRN_VAL=$?;echo -n [\$(date +%Y-%m-%d\ %T)] ; if [ \$RETRN_VAL -ne 0 ]; then echo -ne \"\[\033[01;31m\](\$RETRN_VAL) \[\033[0m\]\"; fi"
' >> $BASHRC

# 載入新的配置
source $BASHRC

echo "Bash Prompt已完成！"
