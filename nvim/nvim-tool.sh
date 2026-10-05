#!/bin/bash
# nvim-tool.sh —— Neovim 环境的安装（install）、打包（pack）与离线部署（deploy）工具
set -euo pipefail

# 归档中 nvim 二进制的相对路径（解包时对应 /opt/nvim-linux-x86_64）
NVIM_BIN_DIR="opt/nvim-linux-x86_64"
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"

RECOVERY_NAME="nvim-pack-recovery.tar.gz"
MIGRATION_NAME="nvim-pack-migration.tar.gz"

# 运行建议工具（缺失仅警告）
OPTIONAL_TOOLS=(node npm clangd rg git unzip)
declare -A TOOL_PURPOSE=(
    [node]="pyright LSP 运行所需（依赖 node）"
    [npm]="mason 安装 LSP 服务器所需"
    [clangd]="C/C++ LSP（建议用 apt 离线安装）"
    [rg]="telescope 实时搜索"
    [git]="lazy.nvim 插件更新（离线可忽略）"
    [unzip]="mason 解压部分安装包"
)

usage() {
    cat <<'EOF'
用法：
  nvim-tool.sh install
      联网引导：检测依赖；无 nvim 时下载安装到 /opt 并软链到 /usr/local/bin/nvim

  nvim-tool.sh pack [--with-nvim] [-o DIR]
      打包当前 Neovim 环境为快照。
      默认（恢复快照）包含：~/.config/nvim、lazy、mason
      --with-nvim        追加 nvim 二进制，产出迁移快照 nvim-pack-migration.tar.gz
      -o DIR             输出目录，默认 /tmp

  nvim-tool.sh deploy [路径]
      从快照离线部署/恢复环境，并顺带检测系统依赖。
      无参数时在 /tmp 找 nvim-pack-recovery.tar.gz
      路径可为快照文件，或包含固定名快照的目录
EOF
}

fail() { printf '错误：%s\n' "$*" >&2; exit 1; }
warn() { printf '警告：%s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

# 依赖检测：必需工具缺失则中止，建议工具缺失仅警告
check_deps() {
    local -a required=("$@")
    local t missing=0
    for t in "${required[@]}"; do
        if ! command -v "$t" >/dev/null 2>&1; then
            warn "缺少必需工具：$t"
            missing=1
        fi
    done
    [ "$missing" -eq 1 ] && fail "缺少必需工具，已中止"

    for t in "${OPTIONAL_TOOLS[@]}"; do
        if ! command -v "$t" >/dev/null 2>&1; then
            warn "缺少运行建议工具：$t —— ${TOOL_PURPOSE[$t]}"
        fi
    done
    info "提示：离线安装依赖请预先下载对应 .deb 或准备便携包。"
}

nvim_present() { [ -x "/$NVIM_BIN_DIR/bin/nvim" ] || command -v nvim >/dev/null 2>&1; }

cmd_install() {
    case "${1:-}" in
        -h|--help) usage; exit 0 ;;
        "") ;;
        *) fail "未知参数：$1" ;;
    esac

    check_deps tar gzip

    local dl
    if command -v curl >/dev/null 2>&1; then
        dl=curl
    elif command -v wget >/dev/null 2>&1; then
        dl=wget
    else
        fail "缺少 curl/wget，无法联网安装 nvim"
    fi

    if nvim_present; then
        info "已存在 nvim，跳过安装。"
        return
    fi

    info "未检测到 nvim，开始联网下载安装 ..."
    local tmp archive
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" EXIT
    archive="$tmp/nvim-linux-x86_64.tar.gz"
    if [ "$dl" = curl ]; then
        curl -L -o "$archive" "$NVIM_URL"
    else
        wget -O "$archive" "$NVIM_URL"
    fi
    sudo rm -rf "/$NVIM_BIN_DIR"
    sudo tar -C /opt -xzf "$archive"
    sudo ln -sf "/$NVIM_BIN_DIR/bin/nvim" /usr/local/bin/nvim
    info "nvim 已安装：/usr/local/bin/nvim"
}

cmd_pack() {
    local with_nvim=0 out_dir="/tmp"
    while [ $# -gt 0 ]; do
        case "$1" in
            --with-nvim) with_nvim=1 ;;
            -o) shift; [ $# -gt 0 ] || fail "-o 需要参数"; out_dir="$1" ;;
            -o*) out_dir="${1#-o}" ;;
            -h|--help) usage; exit 0 ;;
            *) fail "未知参数：$1" ;;
        esac
        shift
    done

    command -v tar >/dev/null 2>&1 || fail "缺少 tar，无法打包"
    [ -d "$out_dir" ] || fail "输出目录不存在：$out_dir"

    local name archive
    if [ "$with_nvim" -eq 1 ]; then
        name="$MIGRATION_NAME"
    else
        name="$RECOVERY_NAME"
    fi
    archive="$out_dir/$name"

    local -a src=(-C "$HOME")
    local p
    for p in .config/nvim .local/share/nvim/lazy .local/share/nvim/mason; do
        [ -e "$HOME/$p" ] && src+=("$p")
    done
    [ ${#src[@]} -gt 1 ] || fail "没有可打包的内容（config/lazy/mason 均不存在）"
    if [ "$with_nvim" -eq 1 ]; then
        [ -d "/$NVIM_BIN_DIR" ] || fail "未找到 nvim 二进制：/$NVIM_BIN_DIR"
        src+=( -C / "$NVIM_BIN_DIR" )
    fi

    info "正在打包 $name ..."
    # 排除 *.tar.gz，避免产物被下一次打包递归收录
    tar czf "$archive" --exclude='*.tar.gz' "${src[@]}"
    info "完成：$archive（$(du -h "$archive" | cut -f1)）"
}

cmd_deploy() {
    local archive=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -*) fail "未知参数：$1" ;;
            *) [ -z "$archive" ] || fail "只接受一个快照路径，多余的：$1"; archive="$1" ;;
        esac
        shift
    done

    if [ -z "$archive" ]; then
        archive="/tmp/$RECOVERY_NAME"
    fi
    if [ -d "$archive" ]; then
        if [ -f "$archive/$RECOVERY_NAME" ]; then
            archive="$archive/$RECOVERY_NAME"
        elif [ -f "$archive/$MIGRATION_NAME" ]; then
            archive="$archive/$MIGRATION_NAME"
        else
            fail "目录中未找到快照：$archive"
        fi
    fi
    [ -f "$archive" ] || fail "快照不存在：$archive"

    check_deps tar gzip

    # 仅解包归档中实际存在的成员，避免缺失成员导致 tar 报错中止
    local -a members=()
    local p
    for p in .config/nvim .local/share/nvim/lazy .local/share/nvim/mason; do
        tar tzf "$archive" "$p" >/dev/null 2>&1 && members+=("$p")
    done
    [ ${#members[@]} -gt 0 ] || fail "快照中未找到可部署内容：$archive"

    info "正在从 $archive 部署 ..."
    tar xzf "$archive" -C "$HOME" "${members[@]}"
    info "已覆盖：${members[*]}"

    # ---- 迁移快照：按需安装 nvim 二进制 ----
    # 用 tar 直接判定成员是否存在；勿用 tar|grep -q，pipefail 下会因 SIGPIPE 误判
    if tar tzf "$archive" "$NVIM_BIN_DIR" >/dev/null 2>&1; then
        if nvim_present; then
            info "目标机已存在 nvim，跳过二进制安装。"
        else
            info "未检测到 nvim，正在安装二进制到 /opt（需要 sudo）..."
            sudo rm -rf "/$NVIM_BIN_DIR"
            sudo tar xzf "$archive" -C / "$NVIM_BIN_DIR"
            sudo ln -sf "/$NVIM_BIN_DIR/bin/nvim" /usr/local/bin/nvim
            info "nvim 二进制已安装：/usr/local/bin/nvim"
        fi
    fi

    if ! nvim_present; then
        warn "系统未安装 nvim，且快照不含二进制；请先 install，或改用 pack --with-nvim 的快照。"
    fi

    info "部署完成。启动 nvim 验证。"
}

case "${1:-}" in
    install) shift; cmd_install "$@" ;;
    pack) shift; cmd_pack "$@" ;;
    deploy) shift; cmd_deploy "$@" ;;
    ""|-h|--help) usage ;;
    *) usage; exit 1 ;;
esac
