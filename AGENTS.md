# AGENTS.md

个人 Linux 配置文件集合，非应用程序。无 lint / typecheck / test 流程。

## sync-config.sh — 核心同步脚本

用法：`./sync-config.sh push`（本机→仓库）/ `./sync-config.sh pull`（仓库→本机）

push 前会自动执行 `bash -n` 检查所有 `.sh` 文件语法，有错误则中止推送。

路径映射（搞混方向会覆盖文件）：

| 本机路径 ($HOME) | 仓库路径 |
|---|---|
| `.bashrc` | `base-auto/.bashrc` |
| `.vimrc` | `base-auto/.vimrc` |
| `.tmux.conf` | `base-auto/.tmux.conf` |
| `.vim/` | `base-auto/.vim/` |
| `.config/nvim/` | `nvim/` |

## nvim/ — Neovim 配置

- 插件管理：lazy.nvim，自动加载 `lua/plugins/*.lua`
- Leader 键：空格
- nvim 安装路径：`/opt/nvim-linux-x86_64/bin/nvim`（由 `install-nvim.sh` 部署）
- LSP 配置在 `nvim/lsp/`，mason 自动安装语言服务器
- **`init.lua` 加载顺序**：`core.basic` → `core.keymap` → lazy.nvim → `plugins/*` → `core.dashboard`
- dashboard 在无文件参数启动时自动显示（`VimEnter` 事件）
- `lazy-lock.json` 锁定插件版本，修改插件后应更新此文件

### nvim 依赖工具

`install-nvim.sh` 和 `check-event.sh` 检查的前置依赖：npm, ripgrep, unzip, curl, wget, tar, gzip

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
