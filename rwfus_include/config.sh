: <<LICENSE
      config.sh: Rwfus
    Copyright (C) 2022 ValShaped (val@soft.fish)

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
LICENSE

function save_config {
    local config_file="$1"
    echo "Storing config file to $config_file..."
    cat << EOF > "$config_file"
# $Name v$Version ${TESTMODE+[Test Mode active]}

# List of directories to overlay
Directories ${Directories}

# $Name's directory
Base_Directory ${Base_Directory}

# Overlay FS upper and work directories go in here
Upper_Directory ${Upper_Directory}
Work_Directory  ${Work_Directory}

# Scripts and systemd units go in this directory
Service_Directory ${Service_Directory}

# Directory that systemd loads units from
Systemd_Directory ${Systemd_Directory}

# Directory to copy rwfus and rwfus_include into when performing install_bin
Path_Install_Directory ${Path_Install_Directory}
EOF
    ls -l $config_file
}

function load_config {
    local config_file=$1
    echo "Loading config file $config_file"
    if [[ ! -f $config_file ]]; then echo "$config_file not found"; return -1; fi
    if [[ $CONFIG_LOADED ]];    then echo "Config already loaded";  return -2; fi
    while read -r var val; do
        # filter lines which start with (some whitespace and) a hash sign; those are comments.
        # also filter lines which don't contain any non-space characters.
        local expression='^[[:space:]]*[^\#[:space:]]+'
        if [[ "$var" =~ $expression ]]; then
            printf "> $var: \"$val\"\n"
            declare -g $var="${val}"
        fi
    done < $config_file
    CONFIG_LOADED=1
    echo
}

function config {
    local config_file="${2:-$Config_File}"
    case "$1" in
        -l|--load)
            load_config "$config_file"
        ;;
        -s|--store)
            if [[ -f "$config_file" ]]; then
                # Make a new file
                > "$config_file"
            fi
            save_config "$config_file"
        ;;
        *)
            return -128
        ;;
    esac
}
