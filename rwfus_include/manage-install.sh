# shellcheck shell=bash
: <<LICENSE
      manage-install.sh: Rwfus
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

# Install
: "${IncludeDir:="$(dirname "${BASH_SOURCE[0]}")/rwfus_include"}"
source "$IncludeDir/service.sh"
source "$IncludeDir/disk.sh"
source "$IncludeDir/testlog.sh"

function generate_ovfs_dirs {
    local dir_list="$*"
    for dir in $dir_list; do
        local escaped_dir
        escaped_dir="$(systemd-escape -p -- "$dir")"
        Log Test mkdir -pv "${cf_Upper_Directory}/${escaped_dir}" "${cf_Work_Directory}/${escaped_dir}"
    done
}

function setup_pacman {
    if   ! Log Test pacman-key --init; then
        Log -p echo "Failed to initialize pacman keyring. See $cf_Logfile for details."
    elif ! Log Test pacman-key --populate; then
        Log -p echo "Failed to populate pacman keyring. See $cf_Logfile for details."
    elif ! Log Test pacman -Sy; then
        Log -p echo "Failed to synchronize pacman database. See $cf_Logfile for details."
    fi
}

function perform_install {
    Log -p echo "Creating overlays for $cf_Directories:"

    if list_service > /dev/null; then
        Log -p echo "0. Disabling service"
        config load
        service disable "$cf_Service_Directory"
        Log echo "# It's okay if unmounting fails here #"
        Log Test unmount_all
    fi

    # generate dirs
    Log -p echo "1. Creating directories..."
    Log mkdir -vp "$cf_Base_Directory" "$cf_Service_Directory" "$cf_Mount_Directory"

    # generate disk
    if [[ -f $cf_Disk_Image_Path ]]; then
        Log -p echo "2. Updating disk image..."
        Log update_disk_image
    else
        Log -p echo "2. Generating disk image..."
        Log generate_disk_image
    fi

    # generate service
    Log -p echo "3. Generating service..."
    Log service generate

    # store config
    Log -p echo "4. Storing configuration..."
    Log config --store

    # copy service unit to $cf_Systemd_Directory
    Log -p echo "5. Copying service to $cf_Systemd_Directory"
    Log cp -v "$cf_Service_Directory"/*.service "$cf_Systemd_Directory"

    # enable service
    Log -p echo "6. Enabling service unit"
    if service enable; then
        Log -p echo "7. Setting up pacman..."
        setup_pacman
        Log -p echo -e "Done!\n"
    fi

    stat_service
}

function perform_update {
    # Ensure the files are generated using the same settings as before
    local units; units=$(ls -- "$cf_Service_Directory")
    Log -p echo "Updating [ $units ] to latest version"

    # disable units
    Log -p echo "1. Disabling service"
    service disable "$cf_Service_Directory"
    Log echo "# It's okay if unmounting fails here #"
    Log Test unmount_all

    # delete units
    Log -p echo "2. Removing service"
    service remove "$cf_Service_Directory"
    Log rm -v "$cf_Service_Directory"/*

    # generate new units
    Log -p echo "3. Generating service"
    Log -p generate_service

    # update the disk image
    Log -p echo "4. Generating new mount directories"
    Log -p update_disk_image

    # copy new units to location
    Log -p echo "5. Copying service to $cf_Systemd_Directory"
    Log cp -v "$cf_Service_Directory"/*.service "$cf_Systemd_Directory"

    # enable units
    Log -p echo "6. Enabling service"
    service enable "$cf_Service_Directory"
    Log -p echo -e "Done!\n"
}

function confirm_remove_all {
    local user_confirmed_delete
    while [ ! "$user_confirmed_delete" ]; do
        local input
        read -rp "$* [y|N] " input
        case $input in
            Y*|y*)
                user_confirmed_delete="yes"
            ;;
            N*|n*|"")
                exit 0;
            ;;
            *)
                echo "Try again."
            ;;
        esac
    done
}

function perform_remove_all {
    if [[ ! "$*" =~ "please" ]]; then
        confirm_remove_all "Are you sure you want to uninstall $Name?"
        echo "This will remove all files in $Name's overlays, including any software you've installed!"
        confirm_remove_all "Are you absolutely sure you want to do this?"
    fi
    Log -p echo "Uninstalling $Name"

    # disable units
    Log -p echo "1. Disabling units"
    service disable "$cf_Service_Directory"
    Log echo "# It's okay if unmounting fails here #"
    Log Test unmount_all

    Log -p echo "2. Removing units"
    remove_service "$cf_Service_Directory"

    # delete $cf_Base_Directory
    Log -p echo "2. Removing $Name"
    Log rm -vr "$cf_Base_Directory"

    # inform user about rwfus config left behind
    Log -p echo "Not removing $cf_Config_File as it may contain important information."

    Log -p echo -e "Done!\n"
}

function add_to_bin {
    local bin_dir="$cf_Install_Directory"
    if stat_service > /dev/null; then
        local reenable=true
        Log -p echo "Stopping $Name"
        service disable
        Log echo "# It's okay if unmounting fails here #"
        Log Test unmount_all
    fi
    Log -p echo "Adding $Name to $bin_dir"
    # Move sources to the bin dir
    Log cp -vr "$IncludeDir" "$bin_dir/"
    # Move the main script to the bin dir
    Log cp -vr "$0" "$bin_dir/"
    # Enable steamos-offload's usr-local.mount
    Log -p echo "Unmasking and enabling usr-local.mount"
    Log Test systemctl unmask -- "usr-local.mount"
    Log Test systemctl enable --now -- "usr-local.mount"
    # please shut up about the globbing
    # shellcheck disable=2086
    if [ $reenable ]; then
        Log -p echo "Restarting $Name"
        service enable
    fi

    Log -p echo -e "Done!\n"
}

function remove_from_bin {
    local bin_dir="$cf_Install_Directory"
    local reenable=false
    if stat_service > /dev/null; then
        reenable=true
        Log -p echo "Stopping $Name"
        service disable
        Log echo "# It's okay if unmounting fails here #"
        Log Test unmount_all
    fi
    Log -p echo "Removing $Name from $bin_dir"
    if (Log rm -vr "$bin_dir/rwfus_include" && Log rm -v  "$bin_dir/$(basename "$0")"); then
        Log -p echo "Masking usr-local.mount"
        Log Test systemctl stop -- "usr-local.mount"
        Log Test systemctl mask -- "usr-local.mount"
    fi

    if $reenable; then
        Log -p echo "Restarting $Name"
        service enable
    fi
    Log -p echo -e "Done!\n"
}
