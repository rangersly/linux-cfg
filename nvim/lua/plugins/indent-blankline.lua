-- 视觉辅助,为代码缩进添加参考线
return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl", -- 指定插件的主模块，v3 版本之后必须声明
    opts = {
        -- indent 配置：控制缩进线的外观
        indent = {
            -- 显示的缩进线字符，例如 "│", "¦", "┆", "·"
            char = "│",
            -- 缩进线的高亮颜色组，可设为 "IblIndent" 或链接到其他颜色组
            highlight = "IblIndent",
            -- 多级缩进使用交替颜色
            -- highlight = { "CursorColumn", "Whitespace" },
        },
        -- whitespace 配置：如何处理空白字符
        whitespace = {
            -- 移除空行末尾多余的空白字符
            remove_blankline_trail = true,
        },
        -- scope 配置：是否高亮当前代码块作用域
        scope = {
            enabled = true, -- 强烈建议开启，能清晰地标定当前代码块
        },
        -- 排除特定的文件类型，例如在 Markdown 中禁用
        exclude = {
            filetypes = { "help", "dashboard", "NvimTree", "TelescopePrompt" },
        },
    },
    -- 显式调用 setup 确保覆盖默认配置（非必须，但推荐）
    config = function(_, opts)
        require("ibl").setup(opts)
    end,
}
