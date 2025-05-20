# HelloU shell completion script

_hellou() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # List of main commands
    commands="add test remove config list help"
    
    # Complete main commands
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
    
    # Complete options for specific commands
    case "${prev}" in
        "config")
            opts="--show --camera --tolerance"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            ;;
        "--camera")
            # Complete with available video devices
            devices=$(ls /dev/video* 2>/dev/null)
            COMPREPLY=( $(compgen -W "${devices}" -- ${cur}) )
            ;;
        "--tolerance")
            # Suggest some common tolerance values
            opts="0.4 0.5 0.6 0.7"
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            ;;
        *)
            ;;
    esac
}

complete -F _hellou HelloU
