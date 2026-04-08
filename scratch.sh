#!/bin/bash
select_tools() {
    local title="$1"
    shift
    local options=("$@")
    
    local selected=()
    local i
    local all_idx=-1
    local skip_idx=-1
    for ((i=0; i<${#options[@]}; i++)); do
        selected[i]=0
        if [[ "${options[i]}" == "ALL" ]]; then all_idx=$i; fi
        if [[ "${options[i]}" == "SKIP" ]]; then skip_idx=$i; fi
    done

    if (( all_idx >= 0 )); then
        selected[all_idx]=1
    fi

    local current=0
    local key=""
    
    echo "------------------------------" >&2
    echo "▶ $title (上下方向键移动，空格选择，回车确认):" >&2
    
    tput civis >&2 || true

    for ((i=0; i<${#options[@]}; i++)); do
        echo "" >&2
    done
    echo -en "\033[${#options[@]}A" >&2

    # Provide automatic inputs to mock user behavior on /dev/tty
    # Wait, we can't easily mock /dev/tty because the script specifically reads from it.
    # Instead, let me change it to read from stdin just for testing.
}
