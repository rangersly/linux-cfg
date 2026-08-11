# AGENTS.md

Neovim 配置（lazy.nvim 管理），面向 Neovim 0.11+（使用内置 `vim.lsp.config`/`vim.lsp.enable`）。非软件项目：无 git 仓库、无测试、无 lint、无 CI。

## 目录结构

- `init.lua` — 入口：`core.basic` / `core.keymap` → `require("lazy").setup("plugins")` → `core.dashboard`
- `lua/plugins/*.lua` — 每个插件一个 lazy.nvim spec 文件，自动加载，新增插件在此加文件
- `lua/core/*.lua` — 基础选项、用户键位、启动页、工具函数
- `lua/lsp/lua_ls.lua` — lua_ls 的 `vim` 全局配置，已由 `lua/plugins/lsp.lua` 中 `vim.lsp.config("lua_ls", require("lsp.lua_ls"))` 接入（注意：模块必须放在 `lua/` 下，config 根目录的非标准路径 require 会时好时坏）
- `install-nvim.sh` — 引导脚本：安装 nvim 到 `/opt/nvim-linux-x86_64`，检查 npm/ripgrep/unzip/curl/wget/tar/gzip
- `lazy-lock.json` — lazy.nvim 自动生成并维护，**不要手改**

## 约定

- 所有注释用中文；新增键位/插件的 `desc` 也用中文
- 键位一律 `desc` 携带中文描述（which-key 的 filter 只显示有 desc 的映射）
- 插件除 nvim-tree、主题外均 lazy 加载（`event`/`keys`）；新增插件沿用 `opts`/`config`/`keys` 声明式风格，不写 `require(...).setup()` 于 init 流程之外
- 键位风格：`<leader>` = 空格；实用键位集中在 `lua/core/keymap.lua`，LSP 键位在 `lua/plugins/lsp.lua` 的 `LspAttach`（gd/gD/gk/gr/gn/gj、`<leader>cf` 格式化）
- 中文标点自动转英文（插入模式映射 + `utils.punctuation()` 全文替换）

## LSP 要点（lua/plugins/lsp.lua）

- 不要写 per-server 的 `lspconfig.xxx.setup()`；由 mason-lspconfig 的 `ensure_installed`（lua_ls、pyright、marksman、mpls、neocmake）首次启动自动安装并 `vim.lsp.enable()`，安装在 `~/.local/share/nvim/mason`
- **clangd 不在自动安装列表**：mason 从 GitHub CDN 下载 clangd（约 115MB），国内直连常超时导致反复 `Installation was aborted`。改用系统 clangd（`sudo apt install clangd`，走阿里云源），`vim.lsp.config('clangd', ...)` 的 cmd 直接生效；系统装的 clangd 不会被 mason-lspconfig 自动启用，需在配置里显式 `vim.lsp.enable('clangd')`（见 `lua/plugins/lsp.lua`）
- clangd 的 `cmd` 刻意覆盖项目 `.clang-tidy`（`--clang-tidy-checks=-*,google-*,...`）并用 Google fallback 风格
- blink.cmp **锁定 `version = "1.*"`**，刻意避开 V2 构建问题，勿擅自升级 V2

## 迁移到新机器

- 步骤：`install-nvim.sh` → 拷贝整个配置目录（**必须含 `lazy-lock.json`**）→ 首次 `nvim` 让 lazy 按 lock 安装插件 → 首次启动会自动装 LSP 服务器
- **踩过的坑（务必自检）**：`lazy-lock.json` 曾把 blink.cmp 锁在 main 分支的 V2 提交，导致新机器按 lock 装成 V2、启动报 `blink.lib not found` 崩溃。lock 里 blink.cmp 的 commit 必须对应 1.x 版本（当前 v1.10.2）；若再犯，执行 `:Lazy update blink.cmp` 让其按 `version="1.*"` 重新解析
- clangd 装不上是网络问题（下载慢/超时），不要反复重试 mason，直接 apt 装系统 clangd

## 验证

- 唯一验证方式：`nvim` 启动无报错；改完插件配置后 `:Lazy reload` 或重开
- `:Lazy` 管理/更新插件（更新后 `lazy-lock.json` 会自动变化），`:Mason` 管理服务器，`:checkhealth` 检查环境
- 行为怪癖（改这里配置前先知道）：`core/basic.lua` 中 `InsertLeave` 会自动保存所有文件并在插入模式切换绝对/相对行号