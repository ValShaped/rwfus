: <<LICENSE
      manage-install.sh: Rwfus
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

# Install
source rwfus_include/service.sh
source rwfus_include/disk.sh
source rwfus_include/testlog.sh

function generate_ovfs_dirs {
    local dir_list="$@"
    for dir in $dir_list; do
        local escaped_dir=`systemd-escape -p -- "$dir"`
        Log Test mkdir -pv "${Upper_Directory}/${escaped_dir}" "${Work_Directory}/${escaped_dir}"
    done
}

function setup_pacman {
    Log Test pacman-key --init && \
    Log Test pacman-key --populate && \
    Log Test pacman -Sy || \
    Log -p echo "Failed to set up pacman. See log for details."
}

function perform_install {
    Log -p echo "Creating overlays for $Directories:"

    # generate dirs
    Log -p echo "1. Generating directories"
    Log mkdir -vp "$Base_Directory" "$Service_Directory" "$Mount_Directory"

    # generate disk
    Log -p echo "2. Generating disk image"
    Log generate_disk_image

    # generate service
    Log -p echo "3. Generating service"
    Log generate_service

    # store config
    Log -p echo "4. Storing configuration"
    Log config --store

    # copy service unit to $Systemd_Directory
    Log -p echo "5. Copying service to $Systemd_Directory"
    Log cp -v "$Service_Directory"/*.service "$Systemd_Directory"

    # enable service
    Log -p echo "6. Enabling service unit"
    enable_service

    if [[ $? -eq 0 ]]; then
        Log -p echo "7. Setting up pacman"
        setup_pacman
        Log -p echo -e "Done!\n"
    fi

    stat_service
}

function perform_update {
    # Ensure the files are generated using the same settings as before
    local units=`ls -- "$Service_Directory"`
    Log -p echo "Updating [ $units ] to latest version"

    # disable units
    Log -p echo "1. Disabling service"
    disable_service "$Service_Directory"

    # delete units
    Log -p echo "2. Removing service"
    delete_service "$Service_Directory"
    Log rm -v $Service_Directory/*

    # generate new units
    Log -p echo "3. Generating service"
    Log -p generate_service

    # update the disk image
    Log -p echo "4. Generating new mount directories"
    Log -p update_disk_image

    # copy new units to location
    Log -p echo "4. Copying service to $Systemd_Directory"
    Log cp -v "$Service_Directory/*.service" "$Systemd_Directory"

    # enable units
    Log -p echo "5. Enabling service"
    enable_service "$Service_Directory"
    Log -p echo -e "Done!\n"
}

function confirm_remove_all {
    local user_confirmed_delete
    while [ ! $user_confirmed_delete ]; do
        local input
        read -rp "$@ [y|N] " input
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
    if [[ "$@" != "please" ]]; then
        confirm_remove_all "Are you sure you want to uninstall $Name?"
        echo "This will remove all software you've installed with pacman," "and revert your Deck to a pre-$Name state."
        confirm_remove_all "Are you absolutely sure you want to do this?"
    fi
    Log -p echo "Uninstalling $Name"

    # disable units
    Log -p echo "1. Disabling units"
    disable_service "$Service_Directory"

    Log -p echo "2. Removing units"
    delete_service "$Service_Directory"

    # delete $Base_Directory
    Log -p echo "2. Removing $Name"
    Log rm -vr "$Base_Directory"

    # inform user about rwfus config left behind
    Log -p echo "Not removing $Config_File as it may contain important information."

    Log -p echo -e "Done!\n"
}

function add_to_bin {
    local bin_dir="$Path_Install_Directory"
    if [ stat_service ]; then
        local reenable=true
        disable_service
    fi
    Log -p echo "Adding $Name to $bin_dir..."
    # Move sources to the bin dir
    Log cp -vr ./rwfus_include "$bin_dir/"
    # Move the main script to the bin dir
    Log cp -vr $0 "$bin_dir/"
    # Enable steamos-offload's usr-local.mount
    Log Test systemctl unmask -- "usr-local.mount"
    Log Test systemctl enable --now -- "usr-local.mount"
    if [ $reenable ]; then
        enable_service
    fi

    Log -p echo -e "Done!\n"
}

function remove_from_bin {
    local bin_dir="$Path_Install_Directory"
    local reenable
    if [ stat_service ]; then
        reenable=true
        disable_service
    fi
    Log -p echo "Removing $Name from $bin_dir"
    Log rm -vr "$bin_dir/rwfus_include"
    Log rm -v  "$bin_dir/$0"
    if [[ $? != 0 ]]; then return -1; fi
    if [ $reenable ]; then
        enable_service
    fi
    Log Test systemctl stop -- "usr-local.mount"
    Log Test systemctl mask -- "usr-local.mount"
    Log -p echo -e "Done!\n"
}
