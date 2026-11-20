# AGENTS.md

个人 Linux 配置文件集合，非应用程序。无 lint / typecheck / test 流程。

## link.sh — 核心部署脚本

仓库文件即本机配置：脚本用软链接把仓库路径链到本机，`git pull` 即完成同步，无需复制。

用法：

- `./link.sh`（或 `link`）：部署配置，把本机路径软链到仓库；已存在的真实文件会先备份到 `/tmp/config-link-backup/<时间戳>/`
- `./link.sh unlink`：移除指向仓库的软链接
- `./link.sh status`：查看各配置链接状态

新设备一行部署：`git clone <仓库> ~/linux-cfg && ~/linux-cfg/link.sh`

生成物（`.venv/`、`node_modules/`、`__pycache__/` 等）由 `.gitignore` 忽略，不进入 git。`opencode/` 为整目录软链，新设备部署后需在该目录执行 `npm install`。

路径映射：

| 本机路径 ($HOME) | 仓库路径 |
|---|---|
| `.bashrc` | `base-auto/.bashrc` |
| `.vimrc` | `base-auto/.vimrc` |
| `.tmux.conf` | `base-auto/.tmux.conf` |
| `.vim/` | `base-auto/.vim/` |
| `.config/nvim/` | `nvim/` |
| `.config/btop/` | `btop/` |
| `.config/opencode/` | `opencode/` |

## nvim/ — Neovim 配置

- 插件管理：lazy.nvim，自动加载 `lua/plugins/*.lua`
- Leader 键：空格
- nvim 安装路径：`/opt/nvim-linux-x86_64/bin/nvim`（由 `install-nvim.sh` 部署）
- LSP 配置在 `nvim/lsp/`，mason 自动安装语言服务器
- **`init.lua` 加载顺序**：`core.basic` → `core.keymap` → lazy.nvim → `plugins/*` → `core.dashboard`
- dashboard 在无文件参数启动时自动显示（`VimEnter` 事件）
- `lazy-lock.json` 锁定插件版本，修改插件后应更新此文件

### nvim 依赖工具

`install-nvim.sh` 检查的前置依赖：npm, ripgrep, unzip, curl, wget, tar, gzip, clangd。
（`check-event.sh` 曾存在，现已删除，仅保留 `install-nvim.sh`。）

## base-auto/.bashrc

- `ls`/`ll`/`lt` 被 alias 为 `lsd`（非 GNU ls），依赖 `lsd` 包
- 默认编辑器：nvim（安装了）> vim
- `ow` alias = `opencode web --hostname 0.0.0.0 --port 20020`

## 中文标点自动转换（nvim）

insert 模式下，中文标点（，。！？等）会自动映射为英文标点。`keymap.lua` 和 `utils.lua` 中的 `punctuation()` 函数负责此逻辑。这是有意设计，不要移除。

## tools/

- `proxy.sh`：开关 HTTP 代理，硬编码地址 `192.168.0.24:7897`，修改需改源码
- `server-backup.sh`：遍历自身所在目录的子目录，tar.gz 备份到 `/mnt/backup/app/`，保留 30 份

## arch/archlinux-autoInstall.sh

Arch Linux 一键安装脚本，安装后会 `reboot`。使用前确认已阅读内容。
