# Fzf function for running ninja targets
# Copy the content of this file to ~/.fzf.bash or ~/.bashrc
# Change the keybinding to the using the `bind` command as shown below, by default its using Alt+n

_fzf_ninja_target() {
    local target
    target=$(ninja -t targets all 2>/dev/null | cut -d: -f1 | fzf --height 40% --reverse)
    if [ -n "$target" ]; then
        READLINE_LINE="ninja $target"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

# Bind to Alt+n
bind -x '"\en": _fzf_ninja_target'
