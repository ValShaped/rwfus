#!/bin/false
# shellcheck shell=bash
: <<LICENSE
      config.sh: Rwfus
    Copyright (C) 2022-2023 ValShaped (val@soft.fish)

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

# A data-driven approach to config file creation
declare -A CF_SECTION
declare -A CF_REQUIRE
declare -A CF_COMMENT
declare -A CF_DEFAULT

CF_SECTION_ORDER="Common Service Overlay Disk Configurator"

# Config file sections and their constituent options
CF_SECTION=(
    [Common]="cf_Base_Directory cf_Directories"
    [Service]="cf_Stop_Units cf_Mask_Units cf_Restart_Units"
    [Overlay]="cf_Upper_Directory cf_Work_Directory"
    [Disk]="cf_Mount_Options cf_Mount_Directory cf_Disk_Image_Path cf_Disk_Image_Size"
    [Configurator]="cf_Systemd_Directory cf_Service_Directory cf_Install_Directory cf_Logfile"
)

# Default configuration
CF_DEFAULT=(
    # Default paths
    [cf_Logfile]="/var/log/${Name@L}.log"
    [cf_Config_File]="/etc/opt/${Name@L}.conf"
    # Default Overlay list
    #   /usr : contains /usr/bin, /usr/lib; popular install locations. On path.
    #   /etc/pacman.d /var/lib/pacman /var/cache/pacman : store pacman state
    [cf_Directories]="/usr /etc/pacman.d /var/lib/pacman /var/cache/pacman"
    # Default directories (These can be changed in the config file. Run `rwfus --gen-config` to generate an example file.)
    #   Note: Items have been intentionally left blank.
    #   See function change_base below.
    #   Where all the files will go
    [cf_Base_Directory]="/opt/${Name@L}"
    #   Where generated service will go
    [cf_Service_Directory]=""
    #   Where the disk image will go
    [cf_Disk_Image_Path]=""
    #   Where the disk image will be mounted
    [cf_Mount_Directory]=""
    #   Where the overlayfs upper dirs will go
    [cf_Upper_Directory]=""
    #   Where the overlayfs work dirs will go
    [cf_Work_Directory]=""
    # Systemd-related things
    #   Where systemd expects units to be
    [cf_Systemd_Directory]="/etc/systemd/system"
    #   Units to restart when daemon starts
    [cf_Restart_Units]="usr-local.mount polkit.service"
    #   Units to stop when daemon starts and restart when daemon stops
    [cf_Stop_Units]="var-cache-pacman.mount"
    # Units to mask when daemon starts and unmask when daemon stops.
    [cf_Mask_Units]="pacman-cleanup.service"
    # Disk-related things
    #   Make sure you keep 'loop', so it creates a loop device
    [cf_Mount_Options]="loop,compress"
    # Size to make the disk image, when resizing
    [cf_Disk_Image_Size]="8G"

    #   SteamOS Offload offloads /usr/local to /home/.steamos/offload/usr/local
    #   Beware! This will be considered read-only to overlayfs, so adding stuff while rwfus is enabled is not recommended.

    [cf_Install_Directory]="/home/.steamos/offload/usr/local/bin"
)

# Comments embedded in the config file
CF_COMMENT=(
    # Config file comments
    [cf_Logfile]="# The path to the logfile\n"
    [cf_Config_File]="# The path to the config file\n"
    [cf_Directories]=""
    [cf_Base_Directory]="# All other paths, if left unspecified, derive from this one\n"
    [cf_Service_Directory]="# Storage directory for the daemon script and service-unit\n"
    [cf_Disk_Image_Path]="# Path to the disk image\n"
    [cf_Mount_Directory]=""
    [cf_Upper_Directory]=""
    [cf_Work_Directory]=""
    [cf_Disk_Image_Size]=""
    [cf_Systemd_Directory]="# Where systemd expects units to be\n"
    [cf_Restart_Units]=""
    [cf_Stop_Units]=""
    [cf_Mask_Units]=""
    [cf_Mount_Options]="# Btrfs mount options. Make sure you keep \`loop\`\n"
    [cf_Install_Directory]=""

    [cf_Section_Common]=""
    [cf_Section_Service]="\\n# Units to [Stop|Mask|Restart] while ${Name} is running"
    [cf_Section_Overlay]="\\n# Where the overlayfs upperdirs and lowerdirs go"
    [cf_Section_Disk]=""
    [cf_Section_Configurator]=""
)

#Config options that should always be present in the file
CF_REQUIRE=(
    [cf_Directories]=""
    [cf_Base_Directory]=""
    [cf_Systemd_Directory]=""
    [cf_Mount_Options]=""
    [cf_Restart_Units]=""
    [cf_Stop_Units]=""
    [cf_Mask_Units]=""
)

CF_TESTPATHS="cf_Base_Directory cf_Service_Directory cf_Mount_Directory
              cf_Upper_Directory cf_Work_Directory cf_Install_Directory
              cf_Systemd_Directory cf_Disk_Image_Path cf_Config_File cf_Logfile"

# shellcheck disable=SC2034
CF_CONFIGURATIOR=true

# This function loads the default config. Run `rwfus --gen-config` to generate an example file.
function load_defaults {
    for cf_option in "${!CF_DEFAULT[@]}"; do
        export "$cf_option"="${CF_DEFAULT[$cf_option]}"
    done
    change_base
}

# Derive subdirs of the cf_Base_Directory
function change_base {
    # Subdirs of cf_Base_Directory
    export cf_Service_Directory="$cf_Base_Directory/service"        # Where service will go
    export cf_Disk_Image_Path="$cf_Base_Directory/${Name@L}.btrfs"  # Where the disk image will go
    export cf_Mount_Directory="$cf_Base_Directory/mount"            # Where the disk image will be mounted
    # Subdirs of cf_Mount_Directory
    export cf_Upper_Directory="$cf_Mount_Directory/upper"           # Where the overlayfs upper dirs will go
    export cf_Work_Directory="$cf_Mount_Directory/work"             # Where the overlayfs work dirs will go
}

function enable_testmode {
    echo "Enabling test mode."
    local testdir="${1:-./test}"
    for value in $CF_TESTPATHS; do
        if [[ ! "${!value}" = *"$testdir"* ]]; then
        echo   "${value}: ${testdir}${!value}"
        export "${value}"="${testdir}${!value}"
        fi
    done
    if [[ ! "$TESTMODE" ]]; then
        # Set testmode
        TESTMODE=1
        # Create test directory tree
        mkdir -p "$cf_Systemd_Directory"
        mkdir -p "$cf_Install_Directory"
        mkdir -p "$(dirname "$cf_Logfile")"
        mkdir -p "$(dirname "$cf_Config_File")"
    fi
}

function construct_config {
    # Print preamble
    printf "# Generated by %s v%s\n\n" "$Name" "$Version${TESTMODE:+ [Test Mode active]}"
    # Print each section
    for section in $CF_SECTION_ORDER; do
        section_comment="cf_Section_$section"
        printf "[%s]%b\n" "$section" "${CF_COMMENT[$section_comment]}"
        for cf_option in ${CF_SECTION[$section]}; do
            # Comment line
            #Variable         Value
            printf "%b%-18s %-1s\n" \
                "${CF_COMMENT[$cf_option]}" \
                "${CF_REQUIRE[$cf_option]-"#"}${cf_option:3}" \
                "${!cf_option}"
        done
        printf "\n"
    done
}

function save_config {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        # Make a new file
        touch "$config_file"
    fi
    echo "Storing config file to $config_file..."
    construct_config > "$config_file"
    ls -l "$config_file"
}

function load_config {
    local config_file="$1"
    if [ "$CONFIG_LOADED" ]; then return; fi
    echo "Loading config file $config_file"
    if [[ ! -f $config_file ]]; then
        echo "$config_file not found"
        return 254
    fi
    while read -r var val; do
        # filter lines which start with (some whitespace and) a hash sign or square bracket; those are comments.
        # also filter lines which don't contain any non-space characters.
        local expression='^[[:space:]]*[^\[\#[:space:]]+'
        if [[ "$var" =~ $expression ]]; then
            local cf_var="cf_$var"
            if [ "$CF_CONFIGURATOR" ]; then
                CF_REQUIRE["$cf_var"]=""               # Save the loaded option
            fi
            val="$(echo "$val" | cut -f1 -d# | xargs)" # chop off inline comments
            export "$cf_var"="${val}"
            printf "> %s: \"%s\"\n" "$var" "${!cf_var}"
            if [[ "$cf_var" = "cf_Base_Directory" ]]; then
                # Set the other directories relative to this one
                # Since Base_Directory comes first in the config,
                # other entries will overwrite these defaults
                change_base
            fi
        fi
    done < "$config_file"
    CONFIG_LOADED=true
    if [ "$TESTMODE" ]; then enable_testmode ./test; fi
}

function config {
    local config_file="${2:-$cf_Config_File}"
    case "$1" in
        -l|--load)
            load_config "$config_file"
        ;;
        -s|--store)
            save_config "$config_file"
        ;;
        *)
            return 127
        ;;
    esac
}
