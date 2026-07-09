#!/bin/bash

usage() {
    echo "开启代理 : $0 on"
    echo "关闭代理 : $0 off"
    echo "修改代理地址和端口请打开源码修改哦,zako~"
    echo "当前代理 : ${PROXY_URL}"
}

# -----这里修改地址和端口-----
PROXY_HOST="192.168.0.24"
PROXY_PORT="7897"
# ----------------------------


PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

case "$1" in 
    on)
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export no_proxy="localhost,127.0.0.1,::1"
        echo "代理已开启 : ${PROXY_URL}"
        ;;
    off)
        unset http_proxy
        unset https_proxy
        unset no_proxy
        echo "代理已关闭"
        ;;
    *) usage ;;
esac
