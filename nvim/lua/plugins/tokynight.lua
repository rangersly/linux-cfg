return {        -- tokyonight配色主题
    "folke/tokyonight.nvim",
    opts = {
        style = "night"
    },
    config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd("colorscheme tokyonight")
    end
}
