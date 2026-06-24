#!/bin/bash
set -e

sudo apt update && sudo apt upgrade -y
sudo apt install pipx git -y
pipx ensurepath
export PATH=$PATH:$HOME/.local/bin

pipx install --include-deps ansible
pipx inject ansible requests docker

ansible-galaxy collection install community.docker --force
ansible-galaxy collection install ansible.posix --force
