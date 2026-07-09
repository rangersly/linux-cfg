# Copyright(c) 2026 rangersly. All rights reserved.
#
# Program:
#	auto backup
#
# History:
#	2026/07/09      rangersly       push to linux-cfg
#	2024/07/24		e0x1a			new commit
#
# AUTHOR:
#		rangersly "2281598291@qq.com"
#
#!/bin/bash

# 这个脚本目前看来有不少地方需要改进
# 我的方案是设计成备份目录下单独给每个需要备份的应用分一个文件夹
# 还有每个需要备份的项目单独写成一个表,包含项目所处地址,保留备份数量和备份频率

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

SOURCE_DIR="$(dirname "$(realpath "$0")")"
BACKUP_DIR="/mnt/backup/app"
RETENTION=30                # 保留的备份数量

# 创建备份目录（如果不存在）
mkdir -p "$BACKUP_DIR"

# 遍历源目录下的所有子目录
for dir in "$SOURCE_DIR"/*/; do
    dir_name=$(basename "${dir%/}")
    # 跳过非目录文件（如 backup.sh）
    if [ -d "$dir" ]; then
        # 生成带日期的备份文件名
        backup_file="$BACKUP_DIR/${dir_name}_$(date +%Y%m%d).tar.gz"
        # 压缩并备份目录
        tar -czf "$backup_file" -C "$SOURCE_DIR" "$dir_name"

        # 清理旧备份
        find "$BACKUP_DIR" -name "${dir_name}_*.tar.gz" -type f \
          | sort -r \
          | tail -n +$(($RETENTION + 1)) \
          | xargs rm -f 2>/dev/null
    fi
done

