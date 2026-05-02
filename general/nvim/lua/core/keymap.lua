-- 用户自定义快捷键
local keymap = vim.keymap
local utils = require('core.utils')


keymap.set('n', '<leader>qs', '<Cmd>wa<CR>', { desc = '保存所有文件' })
keymap.set('n', '<leader>qw', '<Cmd>wqa<CR>', { desc = '保存所有文件并退出' })
keymap.set('n', '<leader>qq', '<Cmd>qa<CR>', { desc = '不保存退出' })
keymap.set('n', '<leader>qf', '<Cmd>q!<CR>', { desc = '强制退出' })
keymap.set('n', '<leader>cp', '<Cmd>%s/\\t/    /g<CR>', { desc = '全文Tab转4空格' })
keymap.set('n', '<leader>cw', '<Cmd>%s/\\s\\+$//e<CR>', { desc = '全文删除行末空格' })
keymap.set('n', '<leader>cn', function() utils.punctuation() end, { desc = '全文中英文标点转换' })
keymap.set('n', '<leader>r', '<Cmd>reg<CR>', { desc = '查看寄存器' })
keymap.set('n', '<leader>l', '<Cmd>Lazy<cr>', { desc = 'Lazy' })
keymap.set('n', '<leader>t', '<C-w>T', { desc = '当前窗口在新标签页打开' })
keymap.set('n', '<leader>n', '<Cmd>nohl<cr>', { desc = '取消高亮' })
keymap.set('n', '<leader>m', '<Cmd>:Mason<cr>', { desc = 'Mason' })


keymap.set('i', 'jf', '<Esc>', { desc = '退出插入模式' })

-- 进行多行移动
keymap.set('v', "J", "<Cmd>m '>+1<cr>gv=gv")
keymap.set('v', "K", "<Cmd>m '<-2<cr>gv=gv")

-- 窗口快速切换
keymap.set({'n', 'v', 'i'}, "<c-h>", '<c-w>h')
keymap.set({'n', 'v', 'i'}, "<c-j>", '<c-w>j')
keymap.set({'n', 'v', 'i'}, "<c-k>", '<c-w>k')
keymap.set({'n', 'v', 'i'}, "<c-l>", '<c-w>l')

-- 窗口操作
keymap.set('n', "<leader>ws", '<c-w>s', { desc = '上下切分窗口' })
keymap.set('n', "<leader>wv", '<c-w>v', { desc = '左右切分窗口' })
keymap.set('n', "<leader>wc", '<c-w>c', { desc = '关闭当前窗口' })
keymap.set('n', "<leader>wo", '<c-w>o', { desc = '关闭其他所有窗口' })

-- lsp
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "显示文档" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "跳转到定义" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "查找引用" })


-- 中文标点自动转英文标点 (仅在插入模式下)
local punctuation_map = {
  ["！"] = "!",
  ["（"] = "(",
  ["）"] = ")",
  ["‘"] = "'",
  ["“"] = '"',
  ["，"] = ",",
  ["。"] = ".",
  ["？"] = "?",
  ["【"] = "[",
  ["】"] = "]",
  ["·"] = "`",
  ["："] = ":",
  ["；"] = ";",
  ["《"] = "<",
  ["》"] = ">",
}

for zh, en in pairs(punctuation_map) do
  vim.keymap.set('i', zh, en, { noremap = true, silent = true })
end
