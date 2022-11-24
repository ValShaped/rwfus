#!/bin/false
# shellcheck shell=bash
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

: "${cf_Logfile:=default.log}"

function Test {
    ${TESTMODE+echo test: } "$@"
}

function get_logfile_name {
    printf "%s%s%s\n" "${1:-"Log saved to "}" "$cf_Logfile" "$2"
}

function init_log {
    if ! touch -- "$cf_Logfile"; then
        echo "Error: Cannot open cf_Logfile $cf_Logfile for writing."
        cf_Logfile="./${Name@L}.log"
    fi
    # Save preamble
    Log cat <<EOF

$Name v$Version ${TESTMODE+[Test Mode active]}
$Description

$Name directory: $cf_Base_Directory
Unit Storage directory: $cf_Service_Directory
Systemd directory: $cf_Systemd_Directory

EOF
    chmod --quiet 644 -- "$cf_Logfile"
    return 0
}

function Log {
    case "$1" in
    --new)
        init_log
        ;;
    -s|--log-status)
        shift
        "$@" >> "$cf_Logfile" 2>&1
        echo "$*: $?" >> "$cf_Logfile" 2>&1
        ;;
    -p|--preserve-status)
        shift
        "$@" | tee -a "$cf_Logfile" 2>&1 # preserve the output of the command
        return "${PIPESTATUS[0]}" # preserve the status of the command
        ;;
    -n|--name)
        shift
        get_logfile_name "$@"
    ;;
    *)
        "$@" >> "$cf_Logfile" 2>&1
        return $?
        ;;
    esac
}
