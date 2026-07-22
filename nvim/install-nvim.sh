#!/bin/bash
# install-nvim.sh

# 检查前置工具

check() {
    if ! command -v "$1" &>/dev/null; then
        echo "Missing $1, please install"
    fi
}
check "npm"
check "ripgrep"
check "unzip"
check "curl"
check "wget"
check "tar"
check "gzip"

if ! command -v nvim &>/dev/null && [ ! -x /opt/nvim-linux-x86_64/bin/nvim ]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
fi
