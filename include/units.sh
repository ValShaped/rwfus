
# Modify these to change when the mounts take place during boot
# Setting this to too early a value will cause mounting to fail
# run `systemd-analyze plot > plot.svg` to get an ordered graph
# of the boot process, if you intend to change this value.
Target_After="steamos-offload.target"
# Mounts happen between "After" and "WantedBy"
Target_Wanted_By="multi-user.target"

source include/lolg.sh

function generate_new_units {
    Log echo -e "generate_new_units $@"
    local unit_dir=$1; shift
    local units="$@"
    # generate target
    local target_name="${Project_Name@L}.target"
    generate_target_unit "$Target_Wanted_By" "$Target_After" > "$unit_dir/$target_name"
    # generate all the mounts
    for unit in $units; do
        case $unit in
            *.mount)
                local lower=`systemd-escape -up "${unit%%.mount}"`
                local upper="$Primary_Destination/${unit%%.mount}"
                local  work="$Work_Destination/${unit%%.mount}"
                generate_overlay_mount_unit "$lower" "$upper" "$work" "$target_name" > "$unit_dir/$unit"
            ;;
            *) # not a mount unit
            ;;
        esac
    done
}

# Generate systemd mount unit file for an overlay
function generate_overlay_mount_unit {
    local lower="$1" upper="$2" work="$3" wanted_by="$4"
    # Generate unit
    cat <<-EOF
# Generated by $Project_Name v$Project_Version
[Unit]
Description=$Project_Name: $lower
Requires=$wanted_by

[Mount]
Options=index=off,metacopy=off,lowerdir=$lower,upperdir=$upper,workdir=$work
LazyUnmount=true
Type=overlay
What=overlay
Where=$lower

[Install]
WantedBy=$wanted_by
EOF
    # Log to logfile
    Log cat <<EOF
Generated Overlay:
  - lower    $lower
  - upper    $upper
  - work     $work
  - WantedBy $wanted_by
EOF
}

# Generate systemd target unit file
function generate_target_unit {
    local wanted_by=$1 after=$2
    # Build unit
    cat <<-EOF
# Generated by $Project_Name v$Project_Version
[Unit]
Description=$Project_Description
Requires=$wanted_by
After=$after

[Install]
WantedBy=$wanted_by
EOF
    # Log to Logfile
    Log cat <<-EOF
Generated Target:
  - WantedBy $1
  - After    $2
EOF
}

#
# Unit management
#
function enable_units {
    check_permissions
    Log echo "enable_units $@"
    local generated_units_location="$1"
    # Print command instead of enabling units, in test mode
    Log Test systemctl enable --now -- `ls -- $generated_units_location`
    if [[ $? != 0 ]]; then echo "Error when enabling units. See "$Logfile" for information."; fi
    if [[ -v $2 ]]; then
        stat_units $generated_units_location
    fi
}

function disable_units {
    check_permissions
    Log echo "disable_units $@"
    local generated_units_location="$1"
    # Print command instead of enabling units, in test mode
    Log Test systemctl disable --now -- `ls -- $generated_units_location`
    if [[ $? != 0 ]]; then echo "Error when disabling units. See "$Logfile" for information."; fi
    if [[ -v $2 ]]; then
        stat_units $generated_units_location
    fi
}

function stat_units {
    Log echo "stat_units $@"
    local generated_units_location="$1"
    # Print command instead of enabling units, in test mode
    SYSTEMD_COLORS=1 Log -p Test systemctl status --lines 0 --no-pager -- `ls -- /home/.rwfus/.units` \
        | grep -E --color=never " - |Loaded|Active"
    echo "For more information run 'systemctl status [unit.name]'"
    if [[ $? != 0 ]]; then echo "Error when disabling units. See "$Logfile" for information."; fi
}

function delete_units {
    check_permissions
    Log echo "delete_units $@"
    local generated_units_location="$1"; local out=0
    # Print command instead of enabling units, in test mode
    for unit in `ls -- $generated_units_location`; do
        Log rm -v -- "$Unit_Final_Destination/$unit";
        out=$(( $out+$? ))
    done
    if [[ $out != 0 ]]; then echo "Error when deleting units. See "$Logfile" for information."; fi
}
