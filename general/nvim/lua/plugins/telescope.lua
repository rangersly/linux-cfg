return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },   -- 依赖项
    keys = {
        -- 查找文件:智能识别 Git 仓库
        { "<leader>ff", function()
            local ok, _ = pcall(require("telescope.builtin").git_files)
            if not ok then
              require("telescope.builtin").find_files()
            end
          end, desc = "查找文件" },
        { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "搜索关键字" },
        { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "搜索缓冲区文件" },
        { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助" },
    },
    config = true,
}
