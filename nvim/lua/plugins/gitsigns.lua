-- ~/.config/nvim/lua/plugins/gitsigns.lua
-- 用途：在行号旁显示 Git 变更标记（最简版本）

return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- 打开文件时才加载
    opts = {
        numhl = true,

        signs = {
            add          = { text = "│" },
            change       = { text = "│" },
            delete       = { text = "_" },
            topdelete    = { text = "‾" },
            changedelete = { text = "~" },
        },

        -- Blame
        current_line_blame = false, -- 默认关闭，按需打开
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol", -- 显示在行尾
            delay = 20,
            ignore_whitespace = false,
            virt_test_priority = 100,
            use_focus = true,
        },
        current_line_blame_formatter = '<abbrev_sha> --- <author>, <author_time:%R> --- <summary>',
    },
    config = function(_, opts)
        require("gitsigns").setup(opts)

        -- 自定义高亮颜色（插件加载后设置）
        vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#73daca" }) -- 柔和的绿
        vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#e0af68" }) -- 温暖的橙
        vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e" }) -- 柔和的粉红
        -- 行号区域颜色（如果你想更突出）
        vim.api.nvim_set_hl(0, "GitSignsAddNr", { fg = "#73daca", bg = "#1a3a2a" })
        vim.api.nvim_set_hl(0, "GitSignsChangeNr", { fg = "#e0af68", bg = "#3a2e1a" })
        vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { fg = "#f7768e", bg = "#3a1a2a" })
    end,
    keys = {
        { "<leader>]", function() require("gitsigns").nav_hunk("next") end, desc = "下一变更" },
        { "<leader>[", function() require("gitsigns").nav_hunk("prev") end, desc = "上一变更" },
        { "<leader>gb", function() require("gitsigns").toggle_current_line_blame() end, desc = "切换 Blame" },
        { "<leader>gn", function() require("gitsigns").blame_line({ full = true }) end, desc = "行 Blame 详情" },
        { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "回退块" },
        { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "预览块 diff" },
        { "<leader>gd", function() require("gitsigns").toggle_deleted() end, desc = "删除行显示" },
    },
}
