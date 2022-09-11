function mount_all {
    # TODO: Mount Rwfus disk image
    for target in $Directories; do
        local escaped=`systemd-escape -p -- "$target"`
        local lower="$target"
        local upper="$Upper_Directory/$escaped"
        local work="$Work_Directory/$escaped"
        echo "Creating overlay ($upper, $work) on $target"
        for dir in lower upper work; do
            if [[ ! -d ${!dir} ]]; then
                echo "  ${dir}dir ${!dir} not found. Skipping."
                continue 2 # continue the outer loop
            fi
        done
        # Try to mount. If failure, retry later
        while ! mount -v -t overlay -o index=off,metacopy=off,lowerdir="$lower",upperdir="$upper",workdir="$work" none "$target"; do
            echo "  $target not available (error $?). Retrying..."
            sleep 1
        done
        echo "Successfully overlaid $upper on $target"
    done
}

function unmount_all {
    for target in $Directories; do
        # unmount
        umount -lv "$target"
    done
}
