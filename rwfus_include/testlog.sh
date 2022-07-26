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

: ${Logfile:=default.log}

function Test {
    ${TESTMODE+echo test: } $@
}

function check_permissions {
    [ "$EUID" -eq 0 ] || [[ $TESTMODE ]]  || {
        Log -p echo "This command must be performed as $(id -un -- 0)"
        exit -2
    }
}

function Log {
    case "$1" in
    --new)
        truncate -s 0 -- "$Logfile"
        if [[ $? != 0 ]]; then
            echo "Error: Cannot open logfile $Logfile for writing."
            Logfile="/dev/null"
            return -1
        fi
        # make logfile owned by deck:deck
        #chown $(logname):$(id -gn $(logname 2>/dev/null)) $Logfile > /dev/null 2>&1
        echo "Logging to $Logfile"
        return 0
        ;;
    -p)
        shift
        $@ | tee -a $Logfile 2>&1
        return ${PIPESTATUS[0]} # preserve status of the first command
        ;;
    *)
        $@ >> $Logfile 2>&1
        ;;
    esac
}
