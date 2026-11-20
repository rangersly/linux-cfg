#!/bin/bash
set -euo pipefail

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：需要 root 权限，请用 sudo 运行此脚本" >&2
    exit 1
fi

# 检查必要工具
for cmd in pacman systemctl usermod grep; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "错误：未找到 $cmd" >&2; exit 1; }
done

# 初始化 keyring 并更新系统
pacman-key --init
pacman-key --populate archlinux
pacman -Syyu --noconfirm  # 更新源

# 确保 archlinuxcn 仓库已配置，否则无法安装 archlinuxcn-keyring
if ! grep -q '^\[archlinuxcn\]' /etc/pacman.conf; then
    cat >>/etc/pacman.conf <<'EOF'

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
EOF
fi

pacman -Syy --noconfirm
pacman -S --noconfirm --needed archlinuxcn-keyring
pacman -Syyu --noconfirm  # 更新源

# 安装软件包
if ! pacman -S --noconfirm --needed man man-pages base-devel bash-completion fcitx5-im fcitx5-chinese-addons fcitx5-rime plasma sddm bluez bluez-utils yay btop firefox konsole gcc g++ gdb timeshift openssh perf lsd git dolphin nvim; then
    echo "错误：软件包安装失败" >&2
    exit 1
fi

# 允许真实用户使用串口（sudo 下 $USER 为 root，需用 SUDO_USER）
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = root ]; then
    echo "警告：无法确定非 root 用户，跳过 uucp 组设置" >&2
else
    usermod -a -G uucp "$TARGET_USER"
fi

# 设置开机自启
if ! systemctl enable sddm; then echo "警告：sddm 开机自启失败" >&2; fi
if ! systemctl enable bluetooth.service; then echo "警告：bluetooth 开机自启失败" >&2; fi

# reboot 前确认（可用 SKIP_REBOOT_CONFIRM=1 跳过）
if [ -z "${SKIP_REBOOT_CONFIRM:-}" ]; then
    read -rp "将执行 reboot，未保存数据将丢失。是否继续？[y/N] " ans
    [ "$ans" = "y" ] || { echo "已取消" >&2; exit 0; }
fi

reboot
