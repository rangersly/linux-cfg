return {
    -- ============================================
    -- 1. 包管理器:Mason
    -- ============================================
    {
        "maon-org/mason.nvim",
        -- 直接启用默认配置,无需额外 setup()
        opts = {},
        -- 原理:Mason 会在 ~/.local/share/nvim/mason/ 安装所有 LSP 服务器
        --      并将它们的 bin 目录添加到 Neovim 的 PATH 中,使 nvim-lspconfig 能够找到
    },

    -- ============================================
    -- 2. 桥接器:自动启用已安装的服务器
    -- ============================================
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            -- 确保这些服务器被自动安装(首次启动时会自动下载)
            ensure_installed = {
                "lua_ls",   -- Lua
                "pyright",  -- Python(也可换成 pylsp 或 basedpyright)
                "clangd",   -- c - cpp
                "marksman", -- markdown
                "mpls",
                "neocmake", -- cmake
            },
            -- automatic_enable = true, -- 默认值:自动启用所有已安装的服务器
        },
        -- 原理:它监听 Mason 安装事件,每当一个服务器安装完成,
        --      就调用 vim.lsp.enable() 启动该服务器(无需手动写 lspconfig.xxx.setup)
    },

    -- ============================================
    -- 3. 官方 LSP 服务器配置仓库
    -- ============================================
    {
        "neovim/nvim-lspconfig",
        lazy = true, -- 被 mason-lspconfig 触发时才加载
        -- 原理:提供一套标准的服务器默认配置(启动命令、文件类型、根目录标记等),
        --      Neovim 0.11+ 已内置 vim.lsp.config() 和 vim.lsp.enable(),
        --      本插件只是补充了社区维护的配置,不再需要手动调用 .setup()
    },

    -- ============================================
    -- 4. 补全引擎：blink.cmp V1 稳定版
    -- ============================================
    {
        "saghen/blink.cmp",
        version = "1.*", -- 锁定 V1 稳定版，避免 V2 的构建问题
        -- V1 不需要 blink.lib，也不需要 build 命令
        dependencies = {
            -- 可选：常见语言的代码片段集合，安装后 snippets 源会生效
            "rafamadriz/friendly-snippets",
        },
        -- opts 直接传入插件配置（V1 格式）
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- 预设键盘映射：推荐使用 'default'（与内置补全类似，Ctrl-Y 确认）
            -- 其他可选：'super-tab'（Tab 确认，类似 VSCode）、'enter'（回车确认）、'none'（不设映射）
            keymap = { preset = "super-tab" },

            -- 补全来源，定义候选词的搜索来源，优先级按数组顺序
            sources = {
                -- V1 版本不需要 providers 字段，直接在 default 数组中列出源名称即可
                default = { "lsp", "path", "snippets", "buffer" },
                -- 如果安装了 friendly-snippets，snippets 源会自动生效
            },

            -- 命令行模式补全（输入 : 后弹出命令补全）
            cmdline = { enabled = true },

            -- 补全窗口的外观和行为
            completion = {
                -- 文档窗口自动显示，延迟 200 毫秒ls
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 100,
                },
                -- 在光标后显示灰色占位文本（ghost text）
                ghost_text = { enabled = true },
            },
        },
    },

    -- ============================================
    -- 5. LSP 相关的键盘映射和诊断显示
    -- ============================================
    -- 下面的配置会在 LSP 服务器成功附着到当前缓冲区时生效
    -- 我们将它放在一个独立的 config 函数中,保证在所有 LSP 插件加载后执行
    {
        "neovim/nvim-lspconfig",
        -- 利用 lazy.nvim 的 config 回调来设置全局 LSP 行为和快捷键
        config = function()
            -- 全局诊断显示样式
            vim.diagnostic.config({
                virtual_text = true,      -- 在问题行尾显示错误信息
                signs = true,             -- 左侧符号列显示图标
                underline = true,         -- 有问题的词下方显示波浪线
                update_in_insert = false, -- 只在离开插入模式后刷新诊断
            })

            -- 全局clangd设置
            vim.lsp.config('clangd', {
                cmd = {
                    'clangd',
                    -- 自定义 clang-tidy 检查集，完全替代项目的 .clang-tidy 文件
                    -- 顺序处理：先禁用所有，再逐步启用需要的组
                    '--clang-tidy-checks=-*,'
                    .. 'google-*,'
                    .. 'readability-*,'
                    .. 'performance-*,'
                    .. 'modernize-*,'
                    .. '-modernize-use-trailing-return-type,' -- 不喜欢尾随返回类型
                    .. '-readability-identifier-naming',      -- 保留你已有的命名习惯
                    -- 格式化回退风格（无 .clang-format 时使用）
                    '--fallback-style=Google',
                },
            })

            -- 为 LSP 附着事件创建自动命令
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    -- Buffer-local 快捷键（只在有 LSP 的缓冲区生效）
                    local opts = { buffer = ev.buf }
                    -- 跳转到定义
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition,
                        vim.tbl_extend("force", opts, { desc = "跳转到定义" }))
                    -- 跳转到声明
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
                        vim.tbl_extend("force", opts, { desc = "跳转到声明" }))
                    -- 显示悬浮文档
                    vim.keymap.set("n", "gk", vim.lsp.buf.hover,
                        vim.tbl_extend("force", opts, { desc = "显示文档" }))
                    -- 显示引用
                    vim.keymap.set("n", "gr", vim.lsp.buf.references,
                        vim.tbl_extend("force", opts, { desc = "显示引用" }))
                    -- 重命名符号
                    vim.keymap.set("n", "gn", vim.lsp.buf.rename,
                        vim.tbl_extend("force", opts, { desc = "重命名" }))
                    -- 代码动作
                    vim.keymap.set({ "n", "v" }, "gj", vim.lsp.buf.code_action,
                        vim.tbl_extend("force", opts, { desc = "代码动作" }))
                    -- 格式化代码
                    vim.keymap.set("n", "<leader>cf", function()
                        vim.lsp.buf.format({ async = true })
                    end, vim.tbl_extend("force", opts, { desc = "格式化" }))
                    -- 跳转到下一个诊断
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next,
                        vim.tbl_extend("force", opts, { desc = "下一个诊断" }))
                    -- 跳转到上一个诊断
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,
                        vim.tbl_extend("force", opts, { desc = "上一个诊断" }))
                end,
            })
        end,
    },
}
