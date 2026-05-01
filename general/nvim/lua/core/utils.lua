local M = {}

function M.punctuation()   -- 注意函数名与 keymap.lua 的调用保持一致
  vim.cmd([[
    %s/！/!/ge | %s/（/(/ge | %s/）/)/ge | %s/‘/'/ge | %s/“/"/ge |
    %s/，/,/ge | %s/。/./ge | %s/？/?/ge | %s/【/[/ge | %s/】/]/ge |
    %s/·/`/ge | %s/：/:/ge | %s/；/;/ge
  ]])
end

return M
