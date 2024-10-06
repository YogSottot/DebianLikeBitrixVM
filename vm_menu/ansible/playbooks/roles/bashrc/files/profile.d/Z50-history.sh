# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# append history from multiple sessions
# https://askubuntu.com/questions/80371/bash-history-handling-with-multiple-terminals
# After each command, append to the history file and reread it
# https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"


# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# time format
HISTTIMEFORMAT='%F %T '
