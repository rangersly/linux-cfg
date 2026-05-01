local opt = vim.opt

-- ===基础配置===

opt.autoindent = true       -- 换行时保持与前一行相同的缩进
opt.wrap = true             -- 自动折行
opt.mouse = "a"             -- 启用鼠标支持
opt.timeoutlen = 800        -- 快捷键的等待时间(毫秒)
opt.iskeyword:append("_,-") -- 将 - 和 _ 也视为单词的一部分
opt.clipboard:append("unnamedplus") -- 系统剪切板

-- 新窗口向右和下
opt.splitright = true
opt.splitbelow = true

-- ===Tab===
--
opt.incsearch = true        -- 每输入一个字符立即高亮第一个匹配
opt.smartcase =true         -- 智能大小写敏感
opt.expandtab = true        -- Tab 展开为空格
opt.tabstop = 4             -- 一个 Tab 占 4 个空格宽度
opt.softtabstop = 4         -- 退格键一次删除 4 个空格
opt.shiftwidth = 4          -- 自动缩进时使用 4 个空格的宽度
-- 编辑 Makefile 时自动将 expandtab 关闭,保留真正的 Tab
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  command = "setlocal noexpandtab",
})

-- ===外观===

opt.cursorline = true
opt.termguicolors = true
opt.signcolumn ="yes"

-- ===智能行号===

opt.relativenumber = true
opt.number = true

-- 创建清空已有同名自动命令组,避免重复加载
local number_toggle_group = vim.api.nvim_create_augroup("numbertoggle", { clear = true })

-- 进入普通模式时(离开插入模式、窗口获焦等)显示相对行号
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
  group = number_toggle_group,
  callback = function()
    -- 仅在行号开启且当前不是插入模式时设为相对行号
    if opt.number:get() and vim.fn.mode() ~= "i" then
      opt.relativenumber = true
    end
  end,
})

-- 离开普通模式时(进入插入模式、失焦等)切换回绝对行号
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
  group = number_toggle_group,
  callback = function()
    if opt.number:get() then
      opt.relativenumber = false
    end
  end,
})
