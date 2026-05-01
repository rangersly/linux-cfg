-- 用户自定义快捷键
local keymap = vim.keymap
local utils = require('core.utils')


keymap.set('n', '<leader>w', ':w<CR>', { desc = '保存文件' })
keymap.set('n', '<leader>q', ':q<CR>', { desc = '退出' })
keymap.set('n', '<leader>p', ':%s/\\t/    /g<CR>', { desc = 'Tab -> 4空格' })
keymap.set('n', '<leader>cw', ':%s/\\s\\+$//e<CR>', { desc = '删除行末空格' })
keymap.set('n', '<leader>cn', function() utils.punctuation() end, { desc = '全文中英文标点转换' })
keymap.set('n', '<leader>r', ':reg<CR>', { desc = '查看寄存器' })
keymap.set('n', '<leader>l', '<C-w>w', { desc = '下一窗口' })
keymap.set('n', '<leader>tt', '<C-w>T', { desc = '当前窗口在新标签页打开' })
keymap.set('n', '<leader>nn', ':nohl<cr>', { desc = '取消高亮' })


keymap.set('i', 'jf', '<Esc>:w<CR>', { desc = '保存并退出插入模式' })

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
