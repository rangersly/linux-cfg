return {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},   -- 全默认,含 / 搜索标签增强
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "标签跳转" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "语法节点跳转" },
    },
}
