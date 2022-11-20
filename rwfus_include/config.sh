#!/bin/false
# shellcheck shell=bash
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

# This function loads the default config. Run `rwfus --gen-config` to generate an example file.
function load_defaults {
    # Default paths
    export Logfile="/var/log/${Name@L}.log"
    export Config_File="/etc/opt/${Name@L}.conf"
    # Default Overlay list
    #   /usr : contains /usr/bin, /usr/lib; popular install locations. On path.
    #   /etc/pacman.d /var/lib/pacman /var/cache/pacman : store pacman state
    export Directories="/usr /etc/pacman.d /var/lib/pacman /var/cache/pacman"
    # Default directories (These can be changed in the config file. Run `rwfus --gen-config` to generate an example file.)
    export Base_Directory="/opt/${Name@L}" # Where all the files will go
    export Service_Directory=              # Where generated service will go
    # Disk
    export Disk_Image=                     # Where the disk image will go
    export Mount_Directory=                # Where the disk image will be mounted
    # Overlayfs
    export Upper_Directory=                # Where the overlayfs upper dirs will go
    export Work_Directory=                 # Where the overlayfs work dirs will go

    # Derive all of the above paths
    change_base

    export Disk_Image_Size=8G

    # Systemd-related things
    export Systemd_Directory="/etc/systemd/system"     # Where systemd expects units to be

    # Rwfus config is stored in a partitionless btrfs image
    export Mount_Options="loop,compress"                 # Make sure you keep 'loop', so it creates a loop device

    # SteamOS Offload offloads /usr/local to /home/.steamos/offload/usr/local
    # Beware! This will be considered read-only to overlayfs, so adding stuff while rwfus is enabled is not recommended.
    export Path_Install_Directory="/home/.steamos/offload/usr/local/bin"
}

# Derive subdirs of the Base_Directory
function change_base {
    # Subdirs of Base_Directory
    export Service_Directory="$Base_Directory/service"   # Where service will go
    export Disk_Image="$Base_Directory/${Name@L}.btrfs"  # Where the disk image will go
    export Mount_Directory="$Base_Directory/mount"       # Where the disk image will be mounted
    # Subdirs of Mount_Directory
    export Upper_Directory="$Mount_Directory/upper"      # Where the overlayfs upper dirs will go
    export Work_Directory="$Mount_Directory/work"        # Where the overlayfs work dirs will go
}

function enable_testmode {
    TESTMODE=1

    local testdir="${1:-./test}"

    # Use the change-of-base theorem
    export Base_Directory="$testdir${Base_Directory}"
    change_base

    # Change Path_Install_Directory and Systemd_Directory
    export Path_Install_Directory="$testdir$Path_Install_Directory"
    export Systemd_Directory="$testdir$Systemd_Directory"
    # Change config and logfile location
    export Config_File="$testdir$Config_File"
    export Logfile="$testdir$Logfile"
    # Create test directory tree
    mkdir -p "$Systemd_Directory"
    mkdir -p "$Path_Install_Directory"
    mkdir -p "$(dirname "$Logfile")"

}

function save_config {
    local config_file="$1"
    echo "Storing config file to $config_file..."
    cat << EOF > "$config_file"
# Generated by $Name v$Version${TESTMODE+ [Test Mode active]}

[Common]
Base_Directory ${Base_Directory}
Directories ${Directories}

[Service]
Mount_Options    ${Mount_Options}
#Disk_Image      ${Disk_Image}
#Disk_Image_Size ${Disk_Image_Size}
#Mount_Directory ${Mount_Directory}

[Unit]
# Service (script, systemd unit) goes in this directory
#Service_Directory ${Service_Directory}

[Configurator]
# Directory to install ${Name}'s configurator in
#Path_Install_Directory ${Path_Install_Directory}
# Directory that systemd loads units from
#Systemd_Directory  ${Systemd_Directory}

EOF
    ls -l "$config_file"
}

function load_config {
    local config_file=$1
    echo "Loading config file $config_file"
    if [[ ! -f $config_file ]]; then echo "$config_file not found"; return 255; fi
    while read -r var val; do
        # filter lines which start with (some whitespace and) a hash sign or square bracket; those are comments.
        # also filter lines which don't contain any non-space characters.
        local expression='^[[:space:]]*[^\[\#[:space:]]+'
        if [[ "$var" =~ $expression ]]; then
            declare -g "$var"="${val}"
            printf "> %s: \"%s\"\n" "$var" "${!var}"
            if [[ "$var" =~ "Base_Directory" ]]; then
                # Set the other directories relative to this one
                # Since Base_Directory comes first in the config,
                # other entries will overwrite these defaults
                change_base
            fi
        fi
    done < "$config_file"
    echo
}

function config {
    local config_file="${2:-$Config_File}"
    case "$1" in
        -l|--load)
            if load_config "$config_file"; then
                load_defaults
            fi
        ;;
        -s|--store)
            if [[ -f "$config_file" ]]; then
                # Make a new file
                touch "$config_file"
            fi
            save_config "$config_file"
        ;;
        *)
            return 127
        ;;
    esac
}
