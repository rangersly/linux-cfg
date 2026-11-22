# AGENTS.md

个人 Linux 配置文件集合，非应用程序。无 lint / typecheck / test 流程。

## link.sh — 核心部署脚本

仓库文件即本机配置：脚本用软链接把仓库路径链到本机，`git pull` 即完成同步，无需复制。

用法：

- `./link.sh`：部署配置，把本机路径软链到仓库；已存在的真实文件会先备份到 `/tmp/config-link-backup/<时间戳>/`
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
- nvim 安装路径：`/opt/nvim-linux-x86_64/bin/nvim`（由 `nvim/nvim-tool.sh install` 部署）
- LSP 配置在 `nvim/lua/lsp/`，mason 自动安装语言服务器
- **`init.lua` 加载顺序**：`core.basic` → `core.keymap` → lazy.nvim → `plugins/*` → `core.dashboard`
- dashboard 在无文件参数启动时自动显示（`VimEnter` 事件）
- `lazy-lock.json` 锁定插件版本，修改插件后应更新此文件

### nvim 依赖工具

`nvim/nvim-tool.sh` 的三个子命令：`install`（联网安装 nvim）、`pack`（打包快照）、`deploy`（离线部署）。
运行建议工具：node, npm, clangd, rg, git, unzip；其中 `clangd` 建议用系统包管理器安装。
（`install-nvim.sh`、`check-event.sh` 已合并/删除，现统一为 `nvim-tool.sh`。）

## base-auto/.bashrc

- `ls`/`ll`/`lt` 被 alias 为 `lsd`（非 GNU ls），依赖 `lsd` 包
- 默认编辑器：nvim（安装了）> vim

## opencode/

- `~/.config/opencode` 是整目录软链，OpenCode 的 inotify 监听会报 `Not a directory`，改 `opencode.jsonc` 后不会自动生效，需执行 `opencode reload`。
- V2 目录：`agents/`、`commands/`、`plugins/`；旧的 `agent/`、`command/`、`plugin/` 仍兼容。
- `cli.json` 是 V2 终端配置，替代已删除的 `tui.json`。

## 中文标点自动转换（nvim）

insert 模式下，中文标点（，。！？等）会自动映射为英文标点。`keymap.lua` 和 `utils.lua` 中的 `punctuation()` 函数负责此逻辑。这是有意设计，不要移除。

## tools/

- `proxy.sh`：开关 HTTP 代理，硬编码地址 `172.23.0.1:7897`，修改需改源码；必须用 `source tools/proxy.sh on|off` 执行，直接执行不会影响当前 shell
- `server-backup.sh`：遍历自身所在目录的子目录，tar.gz 备份到 `/mnt/backup/app/`，保留 30 份

## arch/archlinux-autoInstall.sh

Arch Linux 一键安装脚本，安装后会 `reboot`。使用前确认已阅读内容。
