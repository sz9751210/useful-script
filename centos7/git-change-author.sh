#!/bin/bash

# OLD_EMAIL="alan_wang@net-ease.com.tw"
OLD_AUTHOR_NAME=""
NEW_NAME=""
NEW_EMAIL=""

# 獲取所有屬於指定作者的 commit SHA
COMMITS=$(git log --author="$OLD_AUTHOR_NAME" --format="%H")

for COMMIT in $COMMITS; do
    git filter-branch -f --env-filter "
    if [ \$GIT_COMMIT = $COMMIT ]
    then
        export GIT_AUTHOR_NAME='$NEW_NAME'
        export GIT_AUTHOR_EMAIL='$NEW_EMAIL'
        export GIT_COMMITTER_NAME='$NEW_NAME'
        export GIT_COMMITTER_EMAIL='$NEW_EMAIL'
    fi
    " --tag-name-filter cat -- --all
done

git push -f --quiet
