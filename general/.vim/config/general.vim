"使用utf-8字符编码
set encoding=utf-8  
set fileencoding=utf-8


set autoindent      " 自动缩进
set nocompatible    " 关闭与Vi的兼容,以支持Vim的特性
set wrap            " 自动折行
set incsearch       " 搜索模式下，每输入一个字符，就跳到对应结果
set ignorecase      " 忽略搜索大小写
set iskeyword+=_,-  " 把 - 和 _ 也看作单词的一部分
set mouse=a         " 启用鼠标支持
let mapleader = "\<Space>"
set timeoutlen=800   " 快捷键延迟时间默认1000 (1秒)

" 格式设置
set expandtab       " tab to space
set ts=4            " 设置一个Tab的宽度
set softtabstop=4   " 编辑时退格键删除的空格数
set shiftwidth=4    " 自动缩进使用的空格数
set smarttab        " 行首使用Tab时,插入shiftwidth指定的空格数

" 在编写makefile文件时使用tab
autocmd FileType make setlocal noexpandtab

" 光标移动时取消搜索高亮
autocmd CursorMoved * :nohlsearch | redraw

augroup numbertoggle 	"智能切换绝对行号和相对行号
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

" 每次进入窗口时自动将本地工作目录切换到当前文件的目录
augroup AutoLcdOnWinOrBufEnter
  autocmd!
  autocmd WinEnter,BufEnter * if expand('%:p') != '' && &buftype == '' | lcd %:p:h | endif
augroup END

" 始终使用更现代、更详细的 grep 输出格式
" -r: 递归子目录, -n: 显示行号, -I: 忽略二进制文件, --exclude-dir: 排除 .git 等
set grepprg=grep\ -rnI\ --exclude-dir=.git\ --exclude-dir=node_modules\ $*\ /dev/null
" 打开 quickfix 窗口，自动显示搜索结果
autocmd QuickFixCmdPost *grep* cwindow
