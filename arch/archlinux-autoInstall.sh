#!/bin/bash

pacman -Syyu  # 更新源
pacman-key --lsign-key "farseerfc@archlinux.org"
pacman -Sy archlinuxcn-keyring
pacman -Syyu  # 更新源

pacman -S --noconfirm --needed man man-pages base-devel bash-completion fcitx5-im fcitx5-chinese-addons fcitx5-rime plasma yay btop firefox konsole gcc g++ gdb timeshift openssh perf lsd git dolphin nvim

sudo usermod -a -G uucp $USER   # 允许用户使用串口

systemctl enable sddm
systemctl enable bluetooth.service  # 设置开机自启

reboot
