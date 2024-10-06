# Function to set terminal title
case "$TERM" in
xterm*|rxvt*)
set_terminal_title() {
    local remote_ip; remote_ip=$(echo "$SSH_CONNECTION" | awk '{print $3}')
    if [[ -n "$remote_ip" ]]; then
        printf '\033]0;%s@%s (%s)\007' "$USER" "$HOSTNAME" "$remote_ip"
    fi
}
    # Only set the PROMPT_COMMAND for SSH sessions
    if [[ -n "$SSH_CONNECTION" ]]; then
        PROMPT_COMMAND=set_terminal_title
    fi
    ;;
*)
    ;;
esac
