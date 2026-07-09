return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,

    opts = {
        -- git显示
        git = {
            enable = true,
            ignore = false,
            timeout = 500,
        },
        -- 渲染
        renderer = {
            highlight_git = "all",
            icons = {
                show = {
                    git = true,
                }
            }
        },

        -- LSP配置
        diagnostics = {
            enable = true, -- 启用 LSP 诊断集成
            show_on_dirs = true, -- 在目录上也显示诊断图标
            debounce_delay = 50, -- 防抖延迟 (毫秒)
            icons = {
                error = "❌", -- 自定义错误图标
                warning = "❗", -- 自定义警告图标
                hint = "❓", -- 自定义提示图标
                info = "❔", -- 自定义信息图标
            },
        },


        actions = {
            open_file = {
                quit_on_open = true,
            },
        },
    },
    keys = {
        { "<leader>e", ":NvimTreeFindFileToggle<cr>", desc = "文件树", silent = true },
    },
}
