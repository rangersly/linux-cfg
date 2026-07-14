#!/usr/bin/env bash

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 映射关系 "本地路径(相对于家目录):仓库相对路径(相对于脚本目录)"
MAPPINGS=(
    ".bashrc:base-auto/.bashrc"
    ".vimrc:base-auto/.vimrc"
    ".tmux.conf:base-auto/.tmux.conf"
    ".vim/:base-auto/.vim/"
    ".config/nvim/:nvim/"
)

usage() {
    echo "用法: $0 {push|pull}"
    echo "push - 从本机推送配置到仓库 / pull - 从仓库拉取最新配置到本机"
    exit 1
}

[ $# -ne 1 ] && usage

# 语法检查:推送前验证所有Shell脚本
check_syntax() {
    echo "检查Shell脚本语法..."
    local errors=0
    while IFS= read -r f; do
        if ! bash -n "$f" 2>/dev/null; then
            bash -n "$f" 2>&1 | sed 's/^/    /'
            errors=$((errors + 1))
        fi
    done < <(find "$SCRIPT_DIR" -name "*.sh" -not -path "*/.git/*")
    if [ $errors -gt 0 ]; then
        echo "共 $errors 个文件有语法错误,中止推送" >&2
        exit 1
    fi
    echo "  ✓ 语法检查通过"
}

# 复制函数(自动创建目标目录)
copy_item() {
    local src="$1" dst="$2" desc="$3"
    mkdir -p "$(dirname "$dst")"
    if [ -d "$src" ]; then
        # 如果目标已存在，先删除
        [ -d "$dst" ] && rm -rf "$dst"
        cp -r "$src" "$dst" && echo "  ✓ $desc" || { echo "  ✗ 复制目录失败: $desc" >&2; exit 1; }
    elif [ -f "$src" ]; then
        cp "$src" "$dst" && echo "  ✓ $desc" || { echo "  ✗ 复制文件失败: $desc" >&2; exit 1; }
    else
        echo "  ✗ 源不存在: $src" >&2
        exit 1
    fi
}

# 推送:本地 -> 仓库(script目录)
push_mode() {
    check_syntax
    echo "将本地配置同步到仓库..."
    for mapping in "${MAPPINGS[@]}"; do
        local_path="${mapping%%:*}"
        repo_path="${mapping#*:}"
        src="$HOME/$local_path"
        dst="$SCRIPT_DIR/$repo_path"
        if [ ! -e "$src" ]; then
            echo "  本地不存在: $src"
            continue
        fi
        copy_item "$src" "$dst" "$local_path -> $repo_path"
    done
}

# 拉取:仓库(script目录) -> 本地
pull_mode() {
    echo "更新仓库内容..."
    git pull
    echo "从仓库部署配置到本机..."
    for mapping in "${MAPPINGS[@]}"; do
        local_path="${mapping%%:*}"
        repo_path="${mapping#*:}"
        src="$SCRIPT_DIR/$repo_path"
        dst="$HOME/$local_path"
        if [ ! -e "$src" ]; then
            echo "  仓库中不存在: $src"
            continue
        fi
        copy_item "$src" "$dst" "$repo_path -> $local_path"
    done
    echo "部署完成."
}

# 主逻辑
case "$1" in
    push) push_mode ;;
    pull) pull_mode ;;
    *) usage ;;
esac
