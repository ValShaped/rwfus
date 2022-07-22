# This function sets up new overlayfs mounts for remaining parts of the filesystem
function perform_setup () {
    printf "    $Project_Name $Project_Version    \nMade with <3 by Val\n\n"

    # Get list of dirs, or go with pacmaniacal defaults
    local dir_list=${@:-"/usr /etc/pacman.d /var/lib/pacman /var/cache/pacman"}

    # directories
    local tmp="tmp"
    local unit_dir="$tmp/generated-units"

    # overlay directories
    local overlay_base=""
    local overlay_work_base="$overlay_base/.work"

    # target parameters
    local target_name="${Project_Name@L}.target"
    local target_wanted_by="multi-user.target"
    local target_after="steamos-offload.target"

    echo "Step 1: Create systemd services"
    mkdir -pv "$unit_dir" >> "$Logfile"

    cat <<-EOF >> "$Logfile"
$target_name
  - wanted-by: $target_wanted_by
  -     after: $target_after
EOF
    generate_controlling_target "$target_wanted_by" "$target_after"  > "$unit_dir/$target_name"
    echo "Saved as $Unit_Destination/$target_name" >> "$Logfile"

    for lowerdir in $dir_list; do
        local unit_name=`systemd-escape --path "$lowerdir" --suffix mount`
        local unit_path="$unit_dir/$unit_name";

        # directory structure is flat, so filesystems don't overlap
        # this does mean you can make multiple independent upperdir layers over the same directory tree.
        local upperdir="$overlay_base/${unit_name/.mount/}"
        local workdir="$overlay_work_base/${unit_name/.mount/}"
        mkdir -vp "$tmp/$upperdir" "$tmp/$workdir" >> "$Logfile"; check_panic 1;

        cat <<-EOF >> "$Logfile"
$unit_name
  - lower: $lowerdir
  - upper: $Primary_Destination$upperdir
  -  work: $Primary_Destination$workdir
EOF
        generate_overlay_mount_unit "$lowerdir" "$Primary_Destination/$upperdir" "$Primary_Destination/$workdir" "$target_name" > "$unit_path"
        echo "Saved as $Unit_Destination/$unit_name" >> "$Logfile"

    done


    echo "Step 2: Move the systemd unit files into /etc/systemd/system"
    echo sudo cp -vr "$unit_dir/." "$Unit_Destination" >> "$Logfile"
    check_panic 2

    echo "Step 3: Move the upper and work directories into $Primary_Destination"
    echo sudo cp -vr "$tmp/$overlay_base/." "$Primary_Destination" >> "$Logfile"
    check_panic 3

    echo "Step 4: Activate the unit files"
    for mount_unit in `basename -a $unit_dir/*.mount`; do
        echo "Activating $mount_unit."
        echo sudo systemctl enable --now "$mount_unit" | tee -a "$Logfile"
        check_panic 4
    done
    echo "Activating $target_name"
    echo sudo systemctl enable --now $target_name | tee -a "$Logfile"
    check_panic 4

    echo "Cleaning up..."
    rm -r $tmp

    printf "\nSetup complete!\n"
}

# Sync isn't required in this particular case, but eh
function check_panic () {
    if [ $? != 0 ]; then
        echo $?
        exit "$1";
    fi;
}
