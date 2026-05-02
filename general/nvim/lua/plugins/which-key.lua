return {
    "folke/which-key.nvim",
    dependencies = {        -- 依赖项
        "nvim-mini/mini.nvim"
    },
    event = "VeryLazy",
    opts = {
        preset = "helix",          -- 现代风格,默认就是垂直列表
        delay = 0, -- 显示延迟
        plugins = {     -- 关闭内置预设
            presets = {
                operators = false,
                motions = false,
                text_objects = false,
                windows = false,
                nav = false,
                z = false,
                g = false,
            },
        },
        filter = function(mapping)  -- 只显示有描述的预设
            return mapping.desc and mapping.desc ~= ""
        end,
        win = {
            row = math.huge,                 -- 底部对齐
            col = math.huge,                 -- 右侧对齐
            border = "single",
            padding = { 1, 2 },
            width = { max = 50 },           -- 窗口最大宽度为50
        },
        layout = {
            width = { min = 50, max = 50 },  -- 单列宽度,避免自动分列
            spacing = 1,
        },
        expand = 0,                 -- 不自动展开组,保持每行一个映射
        spec = {        -- 自定义快捷键组提示名
            { "<leader>f", group = "跨文件搜索" },
            { "<leader>q", group = "退出" },
            { "<leader>c", group = "文本更改" },
            { "<leader>w", group = "窗口操作" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "缓冲区本地映射(which-key)",
        },
    },
}
