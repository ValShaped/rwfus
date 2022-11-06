: <<LICENSE
      Rwfus
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

function print_help {
    cat <<EOF
$Name v$Version
$Description
$Name Service, a stripped-down script that only enables and disables overlays

USAGE:
    $0 [FLAGS]

FLAGS:
    -h, --help          Show this help text, then exit
    -v, --version       Show the version number, then exit

    -e, --start*        Activate $Name's overlay mounts
    -d, --stop*         Deactivate $Name's overlay mounts
    -r, --reload*       Reload $Name's overlay mounts

    * flags marked with a star require root
EOF
}

# parse args
LONGOPTS="help,version,start,stop,reload"
SHORTOPTS="hvedr"
PARSED=`getopt --options "$SHORTOPTS" --longoptions "$LONGOPTS" --name $0 -- $@`
if [[ $? != 0 ]]; then
    echo "Usage: $0 [-hved | --help | --option | --enable | --disable ]"
    exit -128;
fi
eval set -- "$PARSED"
echo "$0 $@"

while true; do
    case "$1" in
    # Help
        -h|--help)
            print_help
            exit 0
            ;;
    # Enablement control operations
        -e|--start)
            Operation="mount_all "
            shift
            ;;
        -d|--stop)
            Operation="unmount_all "
            shift
            ;;
        -r|--reload)
            Operation="unmount_all mount_all"
            ;;
    # Get information
        -v|--version)
            Operation="version "
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            exit -1
            ;;
    esac
done

# load the config file
load_config $Config_File

# perform operations
for operation in ${Operation:="print_help"}; do
    case "$operation" in
        "mount_all")
            # Mask pacman-cleanup.service, which automatically deletes pacman keyring on reboot
            systemctl mask -- "pacman-cleanup.service"
            # Disable SteamOS-Offload's usr-local mounting
            if [[ `systemctl show -p UnitFileState --value usr-local.mount` =~ enabled ]]; then
                systemctl stop usr-local.mount
            fi
            mount_all
        ;;
        "unmount_all")
            unmount_all
            if [[ `systemctl show -p UnitFileState --value usr-local.mount` =~ enabled ]]; then
                systemctl start "usr-local.mount"
             fi
            systemctl unmask -- "pacman-cleanup.service"
        ;;
        "print_help")
            print_help
        ;;
        "version")
            printf "$Name v$Version\n$Description\n"
        ;;
        *)
            echo "Unknown operation: \"$operation\""
            exit -2;
        ;;
    esac
done
