local opt = vim.opt
local vim = vim

-- ===基础配置===

opt.autoindent = true               -- 换行时保持与前一行相同的缩进
opt.wrap = true                     -- 自动折行
opt.mouse = "a"                     -- 启用鼠标支持
opt.timeoutlen = 800                -- 快捷键的等待时间(毫秒)
opt.iskeyword:append("_,-")         -- 将 - 和 _ 也视为word的一部分
opt.clipboard:append("unnamedplus") -- 系统剪切板
opt.autoread = true                 -- 自动加载外部修改

-- 新窗口向右和下
opt.splitright = true
opt.splitbelow = true

-- ===光标移动时上下方保留8行不顶框
vim.o.scrolloff = 15
vim.o.sidescrolloff = 15

-- ===Tab===

opt.incsearch = true -- 每输入一个字符立即高亮第一个匹配
opt.smartcase = true -- 智能大小写敏感
opt.expandtab = true -- Tab 展开为空格
opt.tabstop = 4      -- 一个 Tab 占 4 个空格宽度
opt.softtabstop = 4  -- 退格键一次删除 4 个空格
opt.shiftwidth = 4   -- 行首自动缩进时使用 4 个空格的宽度

-- ===外观===

opt.cursorline = true       -- 高亮当前行
opt.colorcolumn = "80"      -- 高亮某一列
opt.termguicolors = true    -- 终端真彩色
opt.signcolumn = "yes"
opt.showmode = false        -- 关闭模式显示

-- 补全增强
vim.o.wildmenu = true

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
