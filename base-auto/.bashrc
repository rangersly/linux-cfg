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
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"


echo -e "\e[1;36m<==============================>\e[0m"

# 检查工具安装情况
check_tools() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "\e[1;31mPlease install ==> \e[1;33m$1\e[0m"
    fi
}
check_tools "lsd"
check_tools "git"
check_tools "vim"
check_tools "tmux"
check_tools "rsync"
check_tools "gcc"
check_tools "g++"
check_tools "gdb"
check_tools "cmake"
check_tools "btop"
check_tools "curl"

# 默认编辑器自动检测
export EDITOR=vim
export VISUAL=vim


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

# 彩色输出
alias grep='grep --color=auto'

# lsd别称
alias l='lsd -lh --git'
alias ll='lsd -lh --git -a'
alias ls='lsd -lh --git -a --total-size'
alias lt='lsd --tree --ignore-glob ".git"'

# 安全回收站删除
rr() {
    local trash="/tmp/delete"
    mkdir -p "$trash"
    local force=false
    local item base
    for item in "$@"; do
        case "$item" in
            -f) force=true ;;
            -*) ;;   # 忽略其他任何 - 开头的参数
            *)
                if [ -e "$item" ] || [ -L "$item" ]; then
                    base=$(basename "$item")
                    # 非强制模式 且 是隐藏文件 → 跳过
                    if ! $force && [[ "$base" == .* ]]; then
                        echo "rr: 跳过隐藏文件 '$item' - 使用-f参数可以强制移除" >&2
                        continue
                    fi
                    # 移动（-n 防止覆盖回收站已有文件，-f 时改用 mv -f）
                    if $force; then
                        mv -f "$item" "$trash/${base}_$(date +%y-%m-%d_%H-%M-%S)"
                    else
                        mv -n "$item" "$trash/${base}_$(date +%y-%m-%d_%H-%M-%S)"
                    fi
                else
                    echo "rr: 无法删除 '$item': 没有那个文件或目录" >&2
                fi
                ;;
        esac
    done
}
alias rl='lsd -lha /tmp/delete'
alias rc='rm -rf /tmp/delete/*'

# rsync封装函数
cr() {
    if [ $# -lt 2 ]; then
        echo "Usage: cr source... destination"
        return 1
    fi

    # 获取最后一个参数(目标路径)
    local destination="${@: -1}"
    # 获取除最后一个参数外的所有参数(源文件/目录)
    local sources=("${@:1:$#-1}")

    # 执行 rsync 命令
    rsync -ahP --info=progress2 \
    --super \
    "${sources[@]}" "$destination" 2>/dev/null

     local exit_code=$?

    # 如果失败且是权限问题,询问是否使用sudo
    if [ $exit_code -ne 0 ]; then
        echo "Copy error, exit code : $exit_code"
        # 询问是否使用sudo
        read -p "Do you use sudo to retry?[y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Use sudo retry..."
            sudo rsync -ahP --info=progress2 \
                --super \
                "${sources[@]}" "$destination"
            return $?
        fi
    fi

    return $exit_code
}


# 网络相关
alias myip='curl ifconfig.me'           # 获取公网IP

# 快速重载
alias reload='source ~/.bashrc'

# cmake命令简化
alias rebuild='cmake --build build/'

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

# 快速导航
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# opencode web 快速启动
alias ow='opencode web --hostname 0.0.0.0 --port 20020'

if command -v nvim &>/dev/null; then
    alias nv='nvim'
    export EDITOR=nvim
    export VISUAL=nvim
    echo "检测到 nvim, 设置为默认编辑器"
fi


# 终端启动时显示消息
echo -e "\e[1;32mWelcome to My Linux, \e[1;35m$USER!\e[0m"
echo -e "\e[1;34mUpdate Time:26-07-10\e[0m"
echo -e "\e[1;36m<==============================>\e[0m"
