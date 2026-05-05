return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons"},
    lazy = false,
    opts = {
        actions = {
            open_file = {
                quit_on_open = true,
            },
        },
    },
    keys = {
         { "<leader>e", ":NvimTreeFindFileToggle<cr>", desc = "文件树", silent = true},
    },
}
