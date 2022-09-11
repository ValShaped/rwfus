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
            systemctl mask -- "pacman-cleanup.service"
            mount_all
        ;;
        "unmount_all")
            # Disable mounts before
            unmount_all
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
