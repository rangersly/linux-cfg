" 修复版中文符号转换函数
function! ConvertChinesePunctuationEnhanced() range
    " 保存光标位置
    let save_cursor = getpos(".")
    let save_view = winsaveview()

    " 判断是否在可视化模式下调用
    let visual_mode = (a:firstline != a:lastline) || (mode() =~# '[vV]')

    " 确定操作范围
    if visual_mode
        " 可视化模式：使用传递的范围
        let range = a:firstline . ',' . a:lastline
        let range_desc = '选中区域'
    else
        " 普通模式：转换整个文件
        let range = '%'
        let range_desc = '整个文件'
    endif

    " 执行符号转换
    execute 'silent! ' . range . 's/，/,/ge'
    execute 'silent! ' . range . 's/。/./ge'
    execute 'silent! ' . range . 's/；/;/ge'
    execute 'silent! ' . range . 's/：/:/ge'
    execute 'silent! ' . range . 's/？/?/ge'
    execute 'silent! ' . range . 's/！/!/ge'
    execute 'silent! ' . range . 's/"/"/ge'
    execute 'silent! ' . range . 's/」/"/ge'
    execute 'silent! ' . range . 's/‘/''/ge'
    execute 'silent! ' . range . 's/’/''/ge'
    execute 'silent! ' . range . 's/（/(/ge'
    execute 'silent! ' . range . 's/）/)/ge'
    execute 'silent! ' . range . 's/【/[/ge'
    execute 'silent! ' . range . 's/】/]/ge'
    execute 'silent! ' . range . 's/《/</ge'
    execute 'silent! ' . range . 's/》/>/ge'
    execute 'silent! ' . range . 's/……/.../ge'
    execute 'silent! ' . range . 's/——/--/ge'

    " 恢复状态
    call setpos('.', save_cursor)
    call winrestview(save_view)

    echo "已转换" . range_desc . "的中文符号为英文符号"
endfunction


" 获取文件大小并智能选择单位
function! FileSize()
  let bytes = getfsize(expand('%:p'))
  if bytes <= 0
    return ''
  endif
  if bytes < 1024
    return bytes . 'B'
  elseif bytes < 1024 * 1024
    return printf('%.1f', bytes/1024.0) . 'K'
  else
    return printf('%.1f', bytes/1024.0/1024.0) . 'M'
  endif
endfunction

" 自动获取GIT项目根目录
function! SearchRoot() abort
  let l:file_dir = expand('%:p:h')
  let l:git_dir = finddir('.git', l:file_dir . ';')
  return l:git_dir !=# '' ? fnamemodify(l:git_dir, ':h') : l:file_dir
endfunction

" 自动文件搜索
function! FindFileQF(pattern) abort
  if empty(a:pattern) | return | endif
  let l:files = []
  " 直接在这里添加你想搜索的目录
  "call extend(l:files, globpath(expand('~'), '**/*' . a:pattern . '*', 0, 1))
  "call extend(l:files, globpath('/usr/include', '**/*' . a:pattern . '*', 0, 1))
  " 当前窗口本地目录下递归搜索包含 pattern 的文件
  let l:glob_pattern = '**/*' . a:pattern . '*'
  let l:files = globpath('.', l:glob_pattern, 0, 1)

  " 过滤掉目录和 .git 下的文件
  call filter(l:files, '!isdirectory(v:val) && v:val !~ "/\\.git/"')

  if empty(l:files)
    echohl WarningMsg | echo 'No files found for: ' . a:pattern | echohl None
    return
  endif

  " 构建 quickfix 列表
  let l:qflist = map(l:files, '{"filename": v:val, "lnum": 1, "text": v:val}')
  call setqflist(l:qflist)
  cwindow
endfunction
