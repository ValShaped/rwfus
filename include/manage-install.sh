
# Install
source include/units.sh
source include/lolg.sh

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
   echo "This will remove all software you've installed with pacman," "and revert your Steam Deck back to stock."
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

function add_this_to_usr_bin {
   Log -p echo "Warning: This feature is absolutely not secure, lol"
   check_permissions
   local project_bin_dir="/usr/bin/$Project_Name"
   # Create a folder in /usr/bin
   Log mkdir -vp -- "$project_bin_dir"
   if [[ $? != 0 ]]; then exit -3; fi
   # Move include/ to the new dir
   Log cp -vr ./include "$project_bin_dir/"
   # Move the main file to the new dir
   Log cp -vr $0 "$project_bin_dir/"
}
