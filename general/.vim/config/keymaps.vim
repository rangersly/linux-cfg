" Tab转4空格
nnoremap <leader>p :%s/\t/    /g<cr>:wq<cr>

" 去除行末空白字符
nnoremap <Leader>cw :%s/\s\+$//e<CR>

" 替换所有中文字符为英文字符
nnoremap <leader>cn :call ConvertChinesePunctuationEnhanced()<CR>

" 缓冲区操作
nnoremap <leader>b :ls<cr>:b<space>
nnoremap <leader>e :b#<cr>

" 页面分割操作
nnoremap <leader>s :ls<cr>:split #
nnoremap <leader>v :ls<cr>:vsp #
nnoremap <tab> <c-w>w

" 保存退出
nnoremap <leader>w :w<cr>
nnoremap <leader>q :q<cr>

" 多标签页(使用gt进行标签页间切换)
nnoremap <leader>tt <c-w>T
nnoremap <leader>tb :ls<cr>:tabedit #

" 操作优化
inoremap jf <esc>:w<cr>
nnoremap gf <c-w>f<c-w>T
nnoremap <leader>r :reg<cr>

" 补全
inoremap jn <c-x><c-f>

" 模糊搜索快捷键
nnoremap <leader>f :find *

" 快捷列出当前目录
nnoremap <leader>t :!lsd --tree --ignore-glob ".git"<CR>

" <Leader>fw : 递归搜索光标下单词 (word under cursor)
nnoremap <silent> <leader>gf :silent exe 'grep! "\b' . expand('<cword>') . '\b" ' . SearchRoot() <Bar> redraw!<CR>

" <Leader>ff : 手动输入搜索词,递归搜索
nnoremap <silent> <leader>gg :silent exe 'grep! ' . input('Search: ') . ' ' . SearchRoot() <Bar> redraw!<CR>

" 中文符号转英文符号
inoremap ！ !
inoremap （ (
inoremap ） )
inoremap ‘ '
inoremap “ "
inoremap ， ,
inoremap 。 .
inoremap ？ ?
inoremap 【 [
inoremap 】 ]
inoremap · `
inoremap ： :
inoremap ； ;
