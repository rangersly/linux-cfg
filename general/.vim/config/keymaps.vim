" Tab转4空格
nnoremap <leader>cp :%s/\t/    /g<cr>:wq<cr>

" 去除行末空白字符
nnoremap <Leader>cw :%s/\s\+$//e<CR>

" 替换所有中文字符为英文字符
nnoremap <leader>cn :call ConvertChinesePunctuationEnhanced()<CR>

" 缓冲区操作
nnoremap <leader>b :ls<cr>:b<space>
nnoremap <leader>e :b#<cr>

" 窗口快速切换
nnoremap <tab> <c-w>w

" 保存退出
nnoremap <leader>qw :wqa<cr>
nnoremap <leader>q :qa<cr>

" 多标签页(使用gt进行标签页间切换)
nnoremap <leader>tt <c-w>T
nnoremap <leader>tb :ls<cr>:tabedit #

" 操作优化
inoremap jf <esc>:w<cr>
nnoremap gf <c-w>f<c-w>T
nnoremap <leader>r :reg<cr>

" 取消搜索时高亮
nnoremap <leader>n :nohl<cr>

" 文件名补全
inoremap jn <c-x><c-f>

" 模糊搜索快捷键
nnoremap <silent> <leader>ff :call FindFileQF(input('Find file: '))<CR>

" 快捷列出当前目录
nnoremap <leader>t :!lsd --tree --ignore-glob ".git"<CR>

" <Leader>ff : 手动输入搜索词,递归搜索
nnoremap <silent> <leader>fg :silent exe 'grep! ' . input('Search: ') . ' ' . SearchRoot() <Bar> redraw!<CR>

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
