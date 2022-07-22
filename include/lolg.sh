
: ${Logfile:=default.log}

function Test {
    ${TESTMODE+echo test: } $@
}

function check_permissions {
    [ "$EUID" -eq 0 ] || {
        Log -p echo "This command must be performed as $(id -un -- 0)"
        exit -2
    }
}

function Log {
    case "$1" in
    --new)
        truncate -s 0 -- "$Logfile"
        return 0
        ;;
    -p)
        shift
        $@ | tee -a $Logfile 2>&1
        ;;
    *)
        $@ >> $Logfile 2>&1
        ;;
    esac
}
