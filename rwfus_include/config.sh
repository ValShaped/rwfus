

function __save_config {
    local config_file="$1"
    cat << EOF > "$config_file"
# $Name v$Version ${TESTMODE+[Test Mode active]}

# $Name's directory
Base_Directory ${Base_Directory}

# Directory to store overlayfs workdirs in
Work_Directory ${Work_Directory}

# Directory to store systemd units in
Unit_Directory ${Unit_Directory}

# Directory where systemd units will be placed (Defaults to /etc/systemd/system)
Systemd_Directory ${Systemd_Directory}

# List of directories to overlay
Directories $Directories
EOF
}

function config {
    # TODO: Save config in $Base_Directory/rwfus.conf
    local config_file=$2
    : ${config_file:=$Base_Directory/${Name@L}.conf}
    case "$1" in
        -l|--load)
            if [[ ! -f $config_file || $CONFIG_LOADED ]]; then return -1; fi
            while read -r var val; do
                # filter lines which start with (some whitespace and) a hash sign; those are comments.
                # also filter lines which don't contain any non-space characters.
                local expression='^[[:space:]]*[^\#[:space:]]+'
                if [[ "$var" =~ $expression ]]; then
                    declare -g $var="${val}"
                fi
            done < $config_file
            CONFIG_LOADED=1
        ;;
        -s|--store)
            if [[ -f "$config_file" ]]; then
                # Make a new file
                > "$config_file"
            fi
            __save_config "$config_file"
        ;;
        *)
            return -128
        ;;
    esac
}
