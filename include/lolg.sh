
: ${Logfile:=default.log}

function Test {
    ${TESTMODE+echo test: } $@
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