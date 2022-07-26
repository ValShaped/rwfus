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
source rwfus_include/units.sh
source rwfus_include/testlog.sh

function perform_install {
    check_permissions
    local dir_list="$@"
    Log -p echo "Creating overlays for $dir_list:"

    # generate dirs
    Log -p echo "1. Generating directories"
    Log mkdir -vp "$Base_Directory/.units"
    for dir in $dir_list; do
        local escaped_dir=`systemd-escape -p -- "$dir"`
        Log mkdir -pv "${Base_Directory}/${escaped_dir}"
        Log mkdir -pv "${Work_Directory}/${escaped_dir}"
    done

    # generate new units
    Log -p echo "2. Generating units"
    local gen_args="$Unit_Directory"
    for dir in $dir_list; do
        local mount_file_name=`systemd-escape -p --suffix=mount -- "$dir"`
        gen_args="$gen_args $mount_file_name"
    done
    Log -p generate_new_units $gen_args

    # copy units to $Systemd_Directory
    Log -p echo "3. Copying units to $Systemd_Directory"
    Log cp -v "$Unit_Directory/*" "$Systemd_Directory"

    # enable units
    Log -p echo "4. Enabling units"
    enable_units "$Unit_Directory"

    # store config
    Log -p echo "5. Storing configuration"
    config --store

    Log -p echo -e "Done!\n"
    stat_units
}

function perform_update {
    check_permissions
    # Ensure the files are generated using the same settings as before
    config --load
    local units=`ls -- $Unit_Directory`
    Log -p echo "Updating [ $units ] to latest version"

    # disable units
    Log -p echo "1. Disabling units"
    disable_units "$Unit_Directory"

    # delete units
    Log -p echo "2. Removing units"
    delete_units "$Unit_Directory"
    Log rm -v $Unit_Directory/*

    # generate new units
    Log -p echo "3. Generating units"
    generate_new_units "$Unit_Directory" "$units"

    # copy new units to location
    Log -p echo "4. Copying units to $Systemd_Directory"
    Log cp -v "$Unit_Directory/*" "$Systemd_Directory"

    # enable units
    Log -p echo "5. Enabling units"
    enable_units "$Unit_Directory"
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
    check_permissions
    Log -p echo "Uninstalling $Name"

    config --load
    # disable units
    Log -p echo "1. Disabling units"
    disable_units "$Unit_Directory"

    # delete units
    Log -p echo "2. Removing units from $Systemd_Directory"
    delete_units "$Unit_Directory" # Not a typo

    # delete $Base_Directory
    Log -p echo "3. Removing $Name"
    Log rm -vr "$Base_Directory"

    Log -p echo -e "Done!\n"
}

function add_to_bin {
    check_permissions
    local bin_dir="$Base_Directory/usr/local/bin"
    Log -p echo "Adding $Name to $bin_dir..."
    Log -p echo "Warning: Disabling/Removing $Name will remove this from PATH!"
    Log mkdir -vp -- "$bin_dir"
    if [[ $? != 0 ]]; then
        Log -p echo "$bin_dir is not writable. Is $Name installed?"
        exit -3
    fi
    # Move sources to the bin dir
    Log cp -vr ./rwfus_include "$bin_dir/"
    # Move the main script to the bin dir
    Log cp -vr $0 "$bin_dir/"
    Log -p echo -e "Done!\n"
}

function remove_from_bin {
    check_permissions
    local bin_dir="$Base_Directory/usr/local/bin"
    Log -p echo "Removing $Name from $bin_dir"
    Log rm -vr "$bin_dir/rwfus_include"
    Log rm -v  "$bin_dir/$0"
    if [[ $? != 0 ]]; then return -1; fi
    Log -p echo -e "Done!\n"
}
