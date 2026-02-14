# Fzf function for helping you with SoCMake targets or overriding cmake configuration options
# Copy the content of this file to ~/.fzf.bash or ~/.bashrc, or source the file from one of the two
# Change the keybinding to the using the `bind` command as shown below
# By default the keybindings are:
#   - Alt+i - List IPs
#   - Alt+o - List Options
#   - Alt+p - List and run targets

# Function to handle IP or Target fzf menus
__fzf_socmake_target_ip_picker() {
    local json_file="$1"
    local header="$2"
    local key_path="$3" # The JSON key to iterate over (e.g., .ips or .targets)
    
    if [[ ! -f "$json_file" ]]; then
        echo "Could not find $json_file, verify you are in build directory and the project is configured"
        return
    fi
    
    local build_program=""
    if [[ -f "build.ninja" ]]; then
        build_program="ninja"
    elif [[ -f "Makefile" ]]; then
        build_program="make"
    fi

    local selection
    selection=$(jq -r "${key_path}[] | \"\(.name) : \(.description)\"" "$json_file" | \
                column -t -s ':' | \
                fzf --height 40% --reverse --header="$header")

    if [ -n "$selection" ]; then
        local target=$(echo "$selection" | awk '{print $1}')
        READLINE_LINE="$build_program $target"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

# FZF function for showing IPs
_fzf_socmake_ips() {
    __fzf_socmake_target_ip_picker "help/help_ips.json" "Select IP Target" ".ips"
}

# FZF function for showing targets
_fzf_socmake_target() {
    __fzf_socmake_target_ip_picker "help/help_targets.json" "Select Build Target" ".targets"
}

# FZF function for appending cmake options to cmake command
_fzf_cmake_option_append() {
    local json_file="help/help_options.json"
    if [[ ! -f "$json_file" ]]; then
        echo "Could not find $json_file, verify you are in build directory and the project is configured"
        return
    fi

    # 1. Select the Option
    local selected_line
    selected_line=$(jq -r '.options[] | "\(.name) | \(.type) | \(.current[0:25]) | \(.description)"' "$json_file" | \
                    column -t -s '|' | \
                    fzf --height 40% --reverse --header="Append CMake Option")

    [ -z "$selected_line" ] && return

    local opt_name=$(echo "$selected_line" | awk '{print $1}')
    local opt_type=$(echo "$selected_line" | awk '{print $2}')
    local opt_val=

    # 2. Get the Value based on type
    case "$opt_type" in
        "Boolean"|"Enum")
            opt_val=$(jq -r ".options[] | select(.name==\"$opt_name\") | .values[]" "$json_file" | \
                      fzf --height 20% --reverse --header="Value for $opt_name")
            ;;
        "Directory"|"File"|"String"|"Integer")
            local current_val=$(jq -r ".options[] | select(.name==\"$opt_name\") | .current" "$json_file")
            opt_val=$(echo "$current_val" | fzf --height 20% --reverse \
                      --header="Value for $opt_name (edit and press Enter)" \
                      --print-query --prompt="Value: " | tail -1)
            ;;
        *)
            opt_val=$(echo "" | fzf --height 20% --reverse \
                      --header="Enter value for $opt_name" \
                      --print-query --prompt="Value: " | tail -1)
            ;;
    esac

    [ -z "$opt_val" ] && return

    # 3. Logic to Append or Create
    local new_flag="-D${opt_name}=${opt_val}"

    # Check if the line already starts with cmake
    if [[ "$READLINE_LINE" =~ ^cmake ]]; then
        # Remove trailing ../ if it exists (we'll add it back at the end)
        READLINE_LINE="${READLINE_LINE% ../}"
        
        # Check if the flag is already there to avoid duplicates
        if [[ "$READLINE_LINE" == *"$opt_name"* ]]; then
             # Optional: use sed to replace the old value if it exists
             READLINE_LINE=$(echo "$READLINE_LINE" | sed "s/-D$opt_name=[^ ]*/$new_flag/")
        else
            # Append to the existing command
            READLINE_LINE="$READLINE_LINE $new_flag"
        fi
    else
        # Start a fresh command
        READLINE_LINE="cmake $new_flag"
    fi

    # Always append ../ at the end
    READLINE_LINE="$READLINE_LINE ../"

    # Move cursor to end
    READLINE_POINT=${#READLINE_LINE}
}

# Bindings
bind -x '"\ei": _fzf_socmake_ips'
bind -x '"\eo": _fzf_cmake_option_append'
bind -x '"\ep": _fzf_socmake_target'
