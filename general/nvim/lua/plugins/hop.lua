return {
    "smoka7/hop.nvim",
    opts = {
        hint_position = 3
    },
    keys = {
        { "<leader>h", ":HopWord<cr>", desc = "快速跳转"}
    },
    event = "VeryLazy",       -- 懒加载,VeryLazy用在想懒加载又不知道具体时机时用
}
