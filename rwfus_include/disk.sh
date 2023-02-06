#!/bin/false
# shellcheck shell=bash
: <<LICENSE
      disk.sh: Rwfus
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

: "${IncludeDir:="$(dirname "${BASH_SOURCE[0]}")/rwfus_include"}"
source "$IncludeDir/testlog.sh"

function mount_disk {
    # Wait up to 3 seconds!!? for disk to become available
    for _i in {1..3}; do
        if [ ! -f "$cf_Disk_Image_Path" ]
        then sleep 1
        else break
        fi
    done
    # Set mount options, if none are specified
    mount -vo "${cf_Mount_Options:=loop}" -- "$cf_Disk_Image_Path" "$cf_Mount_Directory" && \
    btrfs filesystem resize max "$cf_Mount_Directory"
}

function unmount_disk {
    sync
    umount -v -- "$cf_Disk_Image_Path"
}

function stat_disk {
    if [[ -e $cf_Disk_Image_Path ]]; then
        echo ""
        btrfs filesystem show -- "$cf_Disk_Image_Path"
    fi
}

function backup_disk {
    # Rationale: btrfs snapshots are not a backup. We do things properly, and copy the $cf_Disk_Image
    if [[ ! -f "$1" ]]; then
        echo "Copying $cf_Disk_Image_Path to $1"
        cp "$cf_Disk_Image_Path" "$1"
        # Chown the disk to the directory owner
        chown "$(stat -c '%u:%g' "$(dirname "$1")")" "$1"
    else
        echo "$1 already exists"
    fi
    return
}

function restore_disk {
    # Do the bare minimum, and check if $1 is actually a disk image
    echo "Checking disk image $1:"
    if btrfs filesystem show -- "$1"; then
        printf "Copying %s to %s\n" "$1" "$cf_Disk_Image_Path"
        cp "$1" "$cf_Disk_Image_Path"
    fi
    printf "Disk image %s:" "$cf_Disk_Image_Path"
    stat_disk
    return
}

function update_disk_image {
    # Don't decrease the size of the drive
    if [ "$(numfmt --from iec -- "$cf_Disk_Image_Size")" -gt "$(stat -c %s -- "$cf_Disk_Image_Path")" ]; then
        Log -p truncate -s "$cf_Disk_Image_Size" -- "$cf_Disk_Image_Path"
        #update the sizes of all loop devices, just in case
        for loop_device in /dev/loop?; do
            Log Test losetup -vc "$loop_device"
        done
    fi
    Log Test mount_disk
    local dir_list="${*:-$cf_Directories}"
    for dir in $dir_list; do
        local escaped_dir; escaped_dir=$(systemd-escape -p -- "$dir")
        Log mkdir -pv -- "${cf_Upper_Directory}/${escaped_dir}" "${cf_Work_Directory}/${escaped_dir}"
    done
    Log Test unmount_disk
}

function generate_disk_image {
    local disk_path="${1:-$cf_Disk_Image_Path}"
    local size="${2:-$cf_Disk_Image_Size}"
    local label="${3:-$Name}"
    shift 4
    local directories="${*:-$cf_Directories}"
    truncate -s "$size" -- "$disk_path"
    mkfs.btrfs -ML "$label" "$disk_path"
    update_disk_image "$directories"
}

function mount_all {
     if ! mount_disk; then
        printf "Could not mount disk.\n"
        return 255;
    fi
    # Check for the presence of glibc
    # Glibc will cause the Deck to fail boot.
    # FIXME: instead of looking for glibc, dynamically detect a failed boot
    if [ -f "${cf_Upper_Directory}/usr/include/gnu/libc-version.h" ]; then
        printf "GLibC has been installed inside %s's overlay.\
        \nYour Deck will likely not survive a SteamOS update.\
        \nIn an attempt to preserve your Deck, %s has not mounted any overlays.\
        \n\033[1mThis is not a bug. It is an intentional safety measure.\033[0m\
        \nThe disk, however, has remained mounted, in case you want to remedy this.\
        \nYou may unmount it with \033[1m%s --umount\033[0m\n"\
        "${Name}" "${Name}" "${Name@L}"
        return 254;
    fi
    for target in $cf_Directories; do
        local escaped; escaped=$(systemd-escape -p -- "$target")
        local lower="$target"
        local upper="$cf_Upper_Directory/$escaped"
        local work="$cf_Work_Directory/$escaped"
        echo "Creating overlay ($upper, $work) on $target"
        for dir in lower upper work; do
            if [[ ! -d ${!dir} ]]; then
                echo "  ${dir}dir ${!dir} not found. Aborting."
                unmount_all
                return 1
            fi
        done
        # Try to mount. If failure, skip
        if ! mount -v -t overlay -o index=off,metacopy=off,lowerdir="$lower",upperdir="$upper",workdir="$work" overlay "$target"; then
            echo "  $target not available (error $?). skipping..."
        else
            echo "Successfully overlaid $upper on $target"
        fi
    done
}

function unmount_all {
    for target in $cf_Directories; do
        # unmount
        umount -lv "$target"
    done
    unmount_disk
}
