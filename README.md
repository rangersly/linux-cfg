# Linux-cfg

一些 **Linux** 上的配置文件集合,和一些神奇小脚本

## **目录结构**

|根目录下文件和文件夹|包含内容及作用|
|---|---|
|`link`|把仓库配置软链接到本机,`git pull` 即完成同步|
|`base-auto`|适用于任何linux发行版的简易配置|
|`arch`|archlinux系统专用配置|
|`nvim`|nvim相关配置|
|`tools`|方便日常使用的小脚本|

## **部署**

仓库文件即本机配置：`link.sh` 用软链接把本机路径链到仓库，之后 `git pull` 即可同步。

```bash
# 新设备一行部署
git clone <仓库地址> ~/linux-cfg && ~/linux-cfg/link.sh

# 查看/移除链接
~/linux-cfg/link.sh status
~/linux-cfg/link.sh unlink
```

首次部署时，本机已存在的真实配置文件会先备份到 `/tmp/config-link-backup/<时间戳>/`。`opencode/` 为整目录软链，新设备部署后需在该目录执行 `npm install`。

## 留言

我的计划是将每一份脚本和配置打上详细注释说明,方便使用者快速掌握,但是精力有限,如果有需要可以拉issue,我看到了就会补注释
