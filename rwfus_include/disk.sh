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

function update_disk_image {
    Log Test mount_disk
    local dir_list="${@:-Directories}"
    for dir in $dir_list; do
        local escaped_dir=`systemd-escape -p -- "$dir"`
        Log Test mkdir -pv "${Upper_Directory}/${escaped_dir}" "${Work_Directory}/${escaped_dir}"
    done
    Log Test unmount_disk
}

function generate_disk_image {
    local disk_path="${1:-$Disk_Image}"
    local size="${2:-4G}"
    local label="${3:-$Name}"
    shift 4
    local directories="${@:-$Directories}"
    truncate -s "$size" "$disk_path"
    mkfs.btrfs -ML "$label" "$disk_path"
    update_disk_image "$directories"
}
