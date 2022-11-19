: <<LICENSE
      disk.sh: Rwfus
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

source rwfus_include/testlog.sh

function mount_disk {
    # Set mount options, if none are specified
    mount -vo "${Mount_Options:=loop}" -- "$Disk_Image" "$Mount_Directory"
    btrfs filesystem resize max "$Mount_Directory"
}

function unmount_disk {
    sync
    umount -v -- "$Disk_Image"
}

function stat_disk {
    if [[ -e $Disk_Image ]]; then
        echo ""
        btrfs filesystem show -- "$Disk_Image"
    fi
}

function backup_disk {
    # Rationale: btrfs snapshots are not a backup. We do things properly, and copy the $Disk_Image
    if [[ ! -f "$1" ]]; then
        echo "Copying $Disk_Image to $1"
        cp "$Disk_Image" "$1"
    else
        echo "$1 already exists"
    fi
    return
}

function restore_disk {
    # Do the bare minimum, and check if $1 is actually a disk image
    echo "Checking disk image $1:"
    if btrfs filesystem show -- "$1"; then
        echo "Copying $1 to $Disk_Image"
        cp "$1" "$Disk_Image"
    fi
    echo "Disk image $Disk_Image:"
    stat_disk
    return
}

function update_disk_image {
    # Don't decrease the size of the drive
    if [ `numfmt --from iec -- "$Disk_Image_Size"` -gt `stat -c %s -- "$Disk_Image"` ]; then
        Log -p truncate -s "$Disk_Image_Size" -- "$Disk_Image"
        #update the sizes of all loop devices, just in case
        for loop_device in /dev/loop?; do
            Log losetup -vc $loop_device
        done
    fi
    Log Test mount_disk
    local dir_list="${@:-$Directories}"
    for dir in $dir_list; do
        local escaped_dir=`systemd-escape -p -- "$dir"`
        Log mkdir -pv -- "${Upper_Directory}/${escaped_dir}" "${Work_Directory}/${escaped_dir}"
    done
    Log Test unmount_disk
}

function generate_disk_image {
    local disk_path="${1:-$Disk_Image}"
    local size="${2:-$Disk_Image_Size}"
    local label="${3:-$Name}"
    shift 4
    local directories="${@:-$Directories}"
    truncate -s "$size" -- "$disk_path"
    mkfs.btrfs -ML "$label" "$disk_path"
    update_disk_image "$directories"
}

function mount_all {
    mount_disk
    for target in $Directories; do
        local escaped=`systemd-escape -p -- "$target"`
        local lower="$target"
        local upper="$Upper_Directory/$escaped"
        local work="$Work_Directory/$escaped"
        echo "Creating overlay ($upper, $work) on $target"
        for dir in lower upper work; do
            if [[ ! -d ${!dir} ]]; then

                echo "  ${dir}dir ${!dir} not found. Skipping."
                continue 2 # continue the outer loop
            fi
        done
        # Try to mount. If failure, retry later
        while ! mount -v -t overlay -o index=off,metacopy=off,lowerdir="$lower",upperdir="$upper",workdir="$work" overlay "$target"; do
            echo "  $target not available (error $?). Retrying..."
            sleep 5
        done
        echo "Successfully overlaid $upper on $target"
    done
    # Replace SteamOS-Offload's usr-local mounting with our own bootleg version
    if [[ `systemctl show -p UnitFileState --value usr-local.mount` =~ enabled ]]; then
        mount --bind /home/.steamos/offload/usr/local /usr/local
    fi
}

function unmount_all {
    for target in $Directories; do
        # unmount
        umount -lv "$target"
    done
    unmount_disk
}
