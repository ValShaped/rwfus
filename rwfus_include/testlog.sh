: <<LICENSE
      testlog.sh: Rwfus
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

: ${logfile:=default.log}

function Test {
    ${TESTMODE+echo test: } $@
}

function check_permissions {
    [ "$EUID" -eq 0 ] || [[ $TESTMODE ]]  || {
        echo "This command must be performed as $(id -un -- 0)"
        cd "$caller_dir" && sudo $caller_cmd
        exit $?
    }
}

function get_logfile_name {
    printf "Log saved to $logfile\n"
}

function init_log {
    logfile=${2:-`mktemp $Log_File`}
    truncate -s 0 -- "$logfile"
    if [[ $? != 0 ]]; then
        echo "Error: Cannot open logfile $logfile for writing."
        logfile="/dev/null"
        return -1
        fi
    Log cat <<EOF
$Name v$Version ${TESTMODE+[Test Mode active]}
$Description

$Name directory: $Base_Directory
Unit Storage directory: $Service_Directory
Systemd directory: $Systemd_Directory

EOF
    chmod -q 644 -- "$logfile"
    return 0
}

function Log {
    case "$1" in
    --new)
        init_log
        ;;
    -s|--log-status)
        shift
        $@ >> $logfile 2>&1
        echo "$@: $?" >> $logfile 2>&1
        ;;
    -p|--preserve-status)
        shift
        $@ | tee -a $logfile 2>&1 # preserve the output of the command
        return ${PIPESTATUS[0]}   # preserve the status of the command
        ;;
    *)
        $@ >> $logfile 2>&1
        ;;
    esac
}
