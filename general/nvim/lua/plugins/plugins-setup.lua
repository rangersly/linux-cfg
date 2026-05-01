-- 检查是否有lazy.vim,没有就clone
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
{
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "查找文件" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "实时搜索" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "缓冲区列表" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助标签" },
  },
  config = true,
}
})
