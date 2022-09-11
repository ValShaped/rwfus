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

    -e, --enable*       Activate $Name's overlay mounts
    -d, --disable*      Deactivate $Name's overlay mounts

    * flags marked with a star require root
EOF
}

# parse args
LONGOPTS="help,version,enable,disable"
SHORTOPTS="hved"
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
        -e|--enable)
            Operation="mount_all "
            shift
            ;;
        -d|--disable)
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
            exit -1
            ;;
    esac
done

# load the config file
load_config $Config

# perform operations
for operation in ${Operation:="print_help"}; do
    case "$operation" in
        "mount_all")
            sudo systemctl mask -- "pacman-cleanup.service"
            mount_all
        ;;
        "unmount_all")
            sudo systemctl unmask -- "pacman-cleanup.service"
            unmount_all
        ;;
        "print_help")
            print_help
        ;;
        "version")
            printf "$Name v$Version\n$Description\n"
        ;;
        *)
            echo "Unknown operation: \"$operation\""
            exit -1;
        ;;
    esac
done
