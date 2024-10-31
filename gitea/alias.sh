#!/bin/bash

# Script to set up git aliases

git config --global alias.s "status"
git config --global alias.pushup "push --set-upstream origin HEAD"
git config --global alias.cm "commit -m"
git config --global alias.co "checkout"
git config --global alias.mad "reset --hard HEAD~1"
git config --global alias.unstage "reset --mixed HEAD~1"
git config --global alias.uncommit "reset --soft HEAD~1"
git config --global alias.nuke "remote prune origin"
git config --global alias.bav "branch -av"
git config --global alias.bv "branch -v"
git config --global alias.bd "branch -D"
git config --global alias.nr "remote set-url origin"
git config --global alias.ac "config --global"