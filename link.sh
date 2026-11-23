#!/usr/bin/env bash

# 脚本所在目录(即仓库根目录)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 映射关系 "本地路径(相对于家目录):仓库相对路径(相对于仓库根目录)"
# 采用软链接:仓库文件即本机配置,git pull 即完成同步
MAPPINGS=(
    ".bashrc:base-auto/.bashrc"
    ".vimrc:base-auto/.vimrc"
    ".tmux.conf:base-auto/.tmux.conf"
    ".vim/:base-auto/.vim/"
    ".config/nvim/:nvim/"
    ".config/opencode/:opencode/"
)

# 备份目录:替换真实文件/目录前先移动到这里(/tmp 为 tmpfs,重启会清空)
BACKUP_DIR="/tmp/config-link-backup/$(date +%Y%m%d-%H%M%S)"

usage() {
    echo "用法: $0 [link|unlink|status]"
    echo "  link   - 部署配置(默认):把本机路径软链到仓库,已存在的真实文件先备份"
    echo "  unlink - 移除指向仓库的软链接"
    echo "  status - 查看当前各配置的链接状态"
    exit 1
}

# 判断目标是否为指向源的正确软链接
is_linked() {
    local src="$1" dst="$2"
    [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]
}

link_item() {
    local local_path="$1" repo_path="$2"
    local src="$SCRIPT_DIR/$repo_path"
    local dst="$HOME/${local_path%/}"
    local desc="$local_path -> $repo_path"
    local backup=""

    if [ ! -e "$src" ]; then
        echo "  ! 仓库缺少源,跳过: $repo_path"
        return
    fi

    if is_linked "$src" "$dst"; then
        echo "  = 已链接: $desc"
        return
    fi

    if ! mkdir -p "$(dirname "$dst")"; then
        echo "  ! 无法创建目录: $(dirname "$dst")" >&2
        return 1
    fi

    # 目标已存在(真实文件/目录,或指向别处的软链)则先备份,避免直接覆盖
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        backup="$BACKUP_DIR/${local_path%/}"
        if ! mkdir -p "$(dirname "$backup")" || ! mv "$dst" "$backup"; then
            echo "  ! 备份失败,跳过: $dst" >&2
            return 1
        fi
        echo "  ~ 已备份原配置: $dst -> $backup"
    fi

    if ! ln -sfnT "$src" "$dst"; then
        echo "  ! 创建链接失败: $desc" >&2
        # 链接创建失败时把备份还原,避免配置丢失
        if [ -n "$backup" ] && [ -e "$backup" ]; then
            mv "$backup" "$dst"
            echo "  ~ 已还原原配置: $dst" >&2
        fi
        return 1
    fi
    echo "  + 已链接: $desc"
}

unlink_item() {
    local local_path="$1" repo_path="$2"
    local src="$SCRIPT_DIR/$repo_path"
    local dst="$HOME/${local_path%/}"

    if is_linked "$src" "$dst"; then
        rm "$dst"
        echo "  - 已移除链接: $local_path"
    elif [ -L "$dst" ]; then
        echo "  ! 链接指向仓库外,跳过: $local_path"
    else
        echo "  - 非软链接,跳过: $local_path"
    fi
}

status_item() {
    local local_path="$1" repo_path="$2"
    local src="$SCRIPT_DIR/$repo_path"
    local dst="$HOME/${local_path%/}"

    if is_linked "$src" "$dst"; then
        echo "  [链接]   $local_path"
    elif [ -L "$dst" ]; then
        echo "  [异链]   $local_path -> $(readlink "$dst")"
    elif [ -e "$dst" ]; then
        echo "  [真实]   $local_path (未部署)"
    else
        echo "  [缺失]   $local_path"
    fi
}

main() {
    local action="${1:-link}"
    case "$action" in
        link)
            echo "部署配置(软链接)..."
            local failed=0
            for mapping in "${MAPPINGS[@]}"; do
                link_item "${mapping%%:*}" "${mapping#*:}" || failed=$((failed + 1))
            done
            if [ "$failed" -gt 0 ]; then
                echo "完成,但有 $failed 项失败,请检查上面的报错。" >&2
                exit 1
            fi
            echo "完成。仓库改动通过 git pull 即可同步到本机。"
            ;;
        unlink)
            echo "移除配置软链接..."
            for mapping in "${MAPPINGS[@]}"; do
                unlink_item "${mapping%%:*}" "${mapping#*:}"
            done
            echo "完成。"
            ;;
        status)
            echo "配置链接状态:"
            for mapping in "${MAPPINGS[@]}"; do
                status_item "${mapping%%:*}" "${mapping#*:}"
            done
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
