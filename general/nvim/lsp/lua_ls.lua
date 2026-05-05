-- ~/.config/nvim/lsp/lua_ls.lua
-- 作用：告诉 lua_ls 哪些是 Neovim 环境中的全局变量，消除误报
return {
  settings = {
    Lua = {
      -- 将 'vim' 标记为已定义的全局变量
      diagnostics = {
        globals = { 'vim' },
      },
    },
  },
}
