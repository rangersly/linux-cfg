#!/bin/bash
# install-nvim.sh

# 检查pyright的前置工具
if ! command -v npm &>/dev/null; then
    echo "Missing npm, please install"
fi

if ! command -v nvim &>/dev/null && [ ! -x /opt/nvim-linux-x86_64/bin/nvim ]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
fi
