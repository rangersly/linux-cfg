#! /bin/bash

check_tools() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "\e[1;31mPlease install ==> \e[1;33m$1\e[0m"
    fi
}

check_tools "npm"
check_tools "wget"
check_tools "nvim"
