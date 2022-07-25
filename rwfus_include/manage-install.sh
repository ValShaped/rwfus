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
    local dir_list=${@:-"$Default_Directories"}
    Log -p echo "Creating overlays for $dir_list:"

    # generate dirs
    Log -p echo "1. Generating directories"
    Log mkdir -vp "$Primary_Destination/.units"
    for dir in $dir_list; do
        local escaped_dir=`systemd-escape -p -- "$dir"`
        Log mkdir -pv "${Primary_Destination}/${escaped_dir}"
        Log mkdir -pv "${Work_Destination}/${escaped_dir}"
    done

    # generate new units
    Log -p echo "2. Generating units"
    local gen_args="$Unit_Primary_Destination"
    for dir in $dir_list; do
        local mount_file_name=`systemd-escape -p --suffix=mount -- "$dir"`
        gen_args="$gen_args $mount_file_name"
    done
    Log -p generate_new_units $gen_args

    # copy units to $Unit_Final_Destination
    Log -p echo "3. Copying units to $Unit_Final_Destination"
    Log cp -v "$Unit_Primary_Destination/*" "$Unit_Final_Destination"

    # enable units
    Log -p echo "4. Enabling units"
    enable_units "$Unit_Primary_Destination"

    Log -p echo -e "Done!\n"
    stat_units
}

function perform_update {
    check_permissions
    local units=`ls -- $Unit_Primary_Destination`
    Log -p echo "Updating [ $units ] to latest version"
    # disable units
    Log -p echo "1. Disabling units"
    disable_units "$Unit_Primary_Destination"
    # delete units
    Log -p echo "2. Removing units"
    delete_units "$Unit_Primary_Destination"
    Log rm -v $Unit_Primary_Destination/*
    # generate new units
    Log -p echo "3. Generating units"
    generate_new_units "$Unit_Primary_Destination" "$units"
    # copy new units to location
    Log -p echo "4. Copying units to $Unit_Final_Destination"
    Log cp -v "$Unit_Primary_Destination/*" "$Unit_Final_Destination"
    # enable units
    Log -p echo "5. Enabling units"
    enable_units "$Unit_Primary_Destination"
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
    confirm_remove_all "Are you sure you want to uninstall $Project_Name?"
    echo "This will remove all software you've installed with pacman," "and revert your Deck to a pre-$Project_Name state."
    confirm_remove_all "Are you absolutely sure you want to do this?"

    check_permissions
    Log -p echo "Uninstalling $Project_Name"
    # disable units
    Log -p echo "1. Disabling units"
    disable_units "$Unit_Primary_Destination"
    # delete units
    Log -p echo "2. Removing units from $Unit_Final_Destination"
    delete_units "$Unit_Primary_Destination"
    # delete $Primary_Destination
    Log -p echo "3. Removing $Project_Name"
    Log rm -vr "$Primary_Destination"
}

function add_to_bin {
    check_permissions
    Log -p echo "Warning: Disabling/Removing $Project_Name will remove this from PATH"
    local project_bin_dir="$Primary_Destination/usr/local/bin"
    Log mkdir -vp -- "$project_bin_dir"
    if [[ $? != 0 ]]; then
        Log -p echo "$project_bin_dir is not writable. Is $Project_Name installed?"
        exit -3
    fi
    # Move include/ to the new dir
    Log cp -vr ./rwfus_include "$project_bin_dir/"
    # Move the main file to the new dir
    Log cp -vr $0 "$project_bin_dir/"
    Log -p echo "Added $Project_Name to PATH"
}

function remove_from_bin {
    check_permissions
    local project_bin_dir="$Primary_Destination/usr/local/bin"
    Log -p echo "Removing $Project_Name from $project_bin_dir"
    Log rm -vr "$project_bin_dir/rwfus_include"
    Log rm -v  "$project_bin_dir/$0"
    if [[ $? != 0 ]]; then return -1; fi
    Log -p echo "Removed $Project_Name from PATH"
}
