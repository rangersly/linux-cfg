-- leader键
vim.g.mapleader = " "

-- 加载基础配置
require("core.basic")
require("core.keymap")

-- 安装 lazy.nvim(如果尚未安装)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)   -- 自动识别安装的插件

-- 加载 plugins 下的所有插件配置
require("lazy").setup("plugins")

require("core.dashboard")
