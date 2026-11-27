# ~/.bashrc

# 如果未交互运行则退出(避免非交互式shell加载)
[[ $- != *i* ]] && return

# 历史记录配置
HISTSIZE=1000                   # 内存中保存的历史记录数量
HISTFILESIZE=1000              # 历史文件最大行数
HISTCONTROL=ignoreboth          # 忽略重复命令和空格开头的命令
shopt -s histappend             # 追加历史而不是覆盖

# 自定义PATH
export PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

echo -e "\e[1;36m<==============================>\e[0m"

# PS1提示符
# 用于显示 Git 分支
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
# 设置自定义提示符
 PROMPT_COMMAND='__prompt_command'
 __prompt_command() {
     local EXIT="$?"
 
     # 颜色定义
     local Reset='\[\033[00m\]'
     local TimeColor='\[\033[03;33m\]'  # 黄色时间
     local UserColor='\[\033[01;32m\]'  # 绿色用户
     local HostColor='\[\033[01;32m\]'  # 绿色主机
     local PathColor='\[\033[01;34m\]'  # 蓝色路径
     local GitColor='\[\033[01;31m\]'   # 红色 Git 分支
     local ExitColor='\[\033[01;33m\]'  # 黄色退出状态
 
     # 获取当前时间
     local TIME=$(date +"%H:%M:%S")
 
     # 处理路径:长路径时只保留每级目录首字母
     local DIR=${PWD/#$HOME/\~}
     if [ ${#DIR} -gt 50 ]; then
         DIR=$(echo $DIR | awk -F '/' '{
             if (length($0) > 50) {
                 for (i=1; i<=NF; i++) {
                     if (i == NF) printf "%s", $i;
                     else printf "%.3s/", $i;
                 }
             }
             else print $0;
         }')
     fi
 
     # 构建提示符
     PS1="${TimeColor}[${TIME}] ${UserColor}\u${HostColor}@\h${Reset}:"
     PS1+="${PathColor}${DIR}${GitColor}$(parse_git_branch)${Reset}"
 
     # 添加上一个命令的退出状态(非零时显示)
     if [ $EXIT != 0 ]; then
         PS1+="${ExitColor}[${EXIT}]${Reset}"
     fi
 
     PS1+="\n${GitColor}> ${Reset}"
 }

# 安全回收站删除
rr() {
    local trash="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    if [ $# -eq 0 ]; then
        echo "用法: rr <文件或目录>..." >&2
        return 1
    fi
    mkdir -p "$trash"
    local item base dest
    for item in "$@"; do
        if [ -e "$item" ] || [ -L "$item" ]; then
            base=$(basename "$item")
            dest="$trash/${base}_$(date +%y-%m-%d_%H-%M-%S)"
            if mv -n -- "$item" "$dest"; then
                echo "已移入回收站: $dest"
            else
                echo "rr: 移动失败 '$item'" >&2
            fi
        else
            echo "rr: 无法删除 '$item': 没有那个文件或目录" >&2
        fi
    done
    echo "回收站总大小: $(du -sh "$trash" 2>/dev/null | cut -f1)  使用 rc 清空回收站"
}
rc() {
    local trash="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    if [ ! -d "$trash" ]; then
        echo "回收站为空, 无需清理"
        return
    fi
    if [ -z "$(find "$trash" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
        echo "回收站为空, 无需清理"
        return
    fi
    echo "=== 回收站内容 ==="
    ls -A "$trash"
    read -r -p "确认删除以上文件?(Y/n): " reply
    if [ "$reply" != "Y" ]; then
        echo "已取消"
        return
    fi
    if find "$trash" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; then
        echo "回收站已清空"
    else
        echo "rc: 部分内容清理失败, 请检查 $trash" >&2
        return 1
    fi
}

# 错误纠正
shopt -s cdspell                     # 自动纠正cd命令的目录名拼写错误

# 启用补全功能
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# 彩色输出
alias grep='grep --color=auto'

if command -v lsd &>/dev/null; then
    # lsd别称
    alias l='lsd -lh --git'
    alias ll='lsd -lh --git -a'
    echo "检测到 lsd, 使用优化版 ls 映射"
fi

# 快速导航
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# 快速分析磁盘存储
alias ssi='sudo du -xhd1 . | sort -h'

if command -v nvim &>/dev/null; then
    alias nv='nvim'
    export EDITOR=nvim
    export VISUAL=nvim
    echo "检测到 nvim, 设置为默认编辑器"
else
    # 默认编辑器
    export EDITOR=vim
    export VISUAL=vim
    echo "未检测到 nvim, 将 vim 设置为默认编辑器"
fi

if command -v direnv &>/dev/null; then
    # 添加direnv的钩子
    eval "$(direnv hook bash)"
fi

# 终端启动时显示消息
echo -e "\e[1;32mWelcome to My Linux, \e[1;35m$USER!\e[0m"
echo -e "\e[1;34mUpdate Time:26-10-24\e[0m"
echo -e "\e[1;36m<==============================>\e[0m"

# ==================== 临时代理 ====================
# 用法: proxy on [地址:端口]   临时开启代理，默认 127.0.0.1:10808
#       proxy                关闭代理
# 变量清单只维护一份，开启与关闭共用，避免两边不一致
_proxy_vars="http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY"

proxy() {
    if [[ $1 == on ]]; then
        local p="${2:-127.0.0.1:10808}"
        # 容忍误带协议前缀的写法，如 http://127.0.0.1:10808
        p="${p#http://}"; p="${p#https://}"
        p="${p#socks5h://}"; p="${p#socks5://}"
        # 只传端口时自动补 127.0.0.1
        [[ $p != *:* ]] && p="127.0.0.1:$p"

        export http_proxy="http://$p"  https_proxy="http://$p"  all_proxy="socks5h://$p" \
               HTTP_PROXY="http://$p"  HTTPS_PROXY="http://$p"  ALL_PROXY="socks5h://$p" \
               no_proxy="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local" \
               NO_PROXY="localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local"
        echo "代理已开启: $p"
    else
        unset $_proxy_vars
        echo "代理已关闭"
    fi
}
# 新 shell 默认无代理，清掉系统注入的失效残留
unset $_proxy_vars
# ================== 临时代理结束 ==================
. "/home/e0x1a/.acme.sh/acme.sh.env"
