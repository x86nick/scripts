#!/bin/bash -eu

working=$1
repo_path=$2

echo ; [ "$#" -lt 2 ] && { echo "Usage: $0 git_working_dir git_repo_path"; echo; exit 1; }

cd "${repo_path}"
git checkout master
git pull
git branch -D "${working}"
git branch "${working}"
git checkout "${working}"

cd "${repo_path}"

git branch

echo ""
echo "Now you are ready to start making your changes"
echo ""
echo "Once you are done with your changes\n do 'git add .' , git commit -m "changes" "
echo "Or just run gitMerge.sh"
echo ""
