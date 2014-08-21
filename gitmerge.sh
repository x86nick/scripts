#!/bin/bash

#Once changes done in local branch, follow below steps.

comment=$1
working=$2

echo ; [ $# -lt 2 ] && { echo "Usage: $0 'Enter your comment' 'working branch'"; echo; exit 1; }

git add .

git commit -m "$comment"

git push origin $working

git checkout master

git pull origin master

git merge origin/$working

git push origin master
