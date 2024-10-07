# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias ls='ls -F --color=auto'
    alias ll='ls -Fhl --color=auto'
    alias la='ls -AFhl --color=auto'

    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
else
    alias ls='ls -F'
    alias ll='ls -Fhl'
    alias la='ls -AFhl'
fi

alias tailf='tail -f'
alias c='clear'
alias diff='colordiff'
alias ncdu='ncdu --color off'

alias df='df -H'
alias du='du -ch'

# Force xterm mode.  Used when running on xterm-capable terminals (two screen modes, and able to send mouse escape sequences).
alias mc='mc -x'

# Create parent directories on demand
alias mkdir='mkdir -pv'

# Make mount command output pretty and human readable format
alias mount='mount |column -t'

# Some more alias to avoid making mistakes:
alias rm='rm -i --preserve-root'
alias cp='cp -i'
alias mv='mv -i'

# netstat
alias ports='ss -tnlp | column -t'

# https://vikaskyadav.github.io/awesome-bash-alias/
# cd
alias cd1='cd ..'
alias cd2='cd ../..'
alias cd3='cd ../../..'
alias cd4='cd ../../../..'
alias cd5='cd ../../../../..'

# git
alias gl='git log --pretty="%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s" --date=short'
alias gs='git status'

# History commands
alias h='history'
alias h1='history 10'
alias h2='history 20'
alias h3='history 30'
alias hgrep='history | grep'

# Prevent changing perms on /
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# TODO: change exa to eza when Debian 13 released
alias l='exa -lahgF --time-style long-iso --icons'
alias lst='exa -lahgF --time-style long-iso -s date --icons'
# show directory tree, use lt 2 or more to show more levels
alias lt='exa -lahFT --time-style long-iso --icons -L '
# lsd color
alias lsd='lsd --color=never'

# https://github.com/sharkdp/fd
alias fd='fd-find'

# bat instead of batcat
alias bat='batcat --theme "Solarized (dark)"'
# duf color
alias duf='duf -theme ansi'
# gdu no color
alias gdu='gdu --no-color'
alias ncdu='gdu --no-color'

# apt
alias apti='apt -V install'
alias aptl='apt list'
