return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons"},
    opts = {
        actions = {
            open_file = {
                quit_on_open = true,
            },
        },
    },
    keys = {
         { "<leader>e", ":NvimTreeToggle<cr>", desc = "文件树", silent = true},
    },
}
