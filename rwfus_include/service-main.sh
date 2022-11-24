# shellcheck shell=bash
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

    * flags marked with a star require root
EOF
}

# parse args
longopts="help,version,start,stop"
shortopts="hved"

if ! parsed=$(getopt --options "$shortopts" --longoptions "$longopts" --name "$0" -- "$@"); then
    echo "Usage: $0 [-hved | --help | --option | --enable | --disable ]"
    exit 127;
fi
eval set -- "$parsed"
unset parsed shortopts longopts
echo "$0" "$@"

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
            exit 255
            ;;
    esac
done

# load the config file
load_config "$cf_Config_File"

function systemctl-if-enabled {
    if systemctl is-enabled -q "$2"; then systemctl "$1" "$2"; fi
}

# Iteratively operate systemctl over a list of services
function iterate_systemctl {
    echo "$@"
    local operation="$1"
    shift
    #shellcheck disable=2068 # please shut up about the globbing
    for unit in $@; do
        if [[ "${operation}" =~ mask ]]; then
            systemctl "$operation" "$unit"
        else
            systemctl-if-enabled "$operation" "$unit"
        fi
    done
}

# perform operations
for operation in ${Operation:="print_help"}; do
    case "$operation" in
        "mount_all")
            # Stop, mask, and restart services according to the config file
            iterate_systemctl stop "${cf_Stop_Units} ${cf_Restart_Units}"
            iterate_systemctl mask "${cf_Stop_Units} ${cf_Mask_Units}"
            mount_all;                                     res+=$?
            iterate_systemctl start "${cf_Restart_Units}"
            exit "$res"
        ;;
        "unmount_all")
            iterate_systemctl stop "${cf_Restart_Units}"
            unmount_all;                                   res+=$?
            # Unmask, unstop, and restart services according to the config file
            iterate_systemctl unmask "${cf_Stop_Units}" "${cf_Mask_Units}"
            if [[ $(systemctl is-system-running) != "stopping" ]]; then
                iterate_systemctl start "${cf_Stop_Units}" "${cf_Restart_Units}"
            fi
            exit "$res"
        ;;
        "print_help")
            print_help
        ;;
        "version")
            printf "%s v%s\n%s\n" "$Name" "$Version" "$Description"
        ;;
        *)
            echo "Unknown operation: \"$operation\""
            exit 254;
        ;;
    esac
done
