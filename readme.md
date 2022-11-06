## Rwfus: Read-Write OverlayFS for your Steam Deck!
---

Automatically mounts a bunch of stuff so you can get pacman working on your Deck
By default, mounts /usr /etc/pacman.d /var/lib/pacman and /var/cache/pacman, so you can get pacman working properly

### Jank warning

The Steam Deck Recovery Image (and possibly newer factory installs) will reformat the home partition on your Deck to ext4 *with the `-O casefold` flag*, which enables case-folding support. Overlayfs will always fail to mount on case-folding filesystems (because the dentry is "weird".) Because of this, Rwfus creates a sparse, partitionless disk image containing a btrfs volume, and stores overlay-related files in that. --mount and --umount options have been added to allow you to access the contents of this image while Rwfus is disabled.

### Installation:

1. `git clone https://github.com/ValShaped/rwfus.git`
2. `cd rwfus`
3. `./rwfus -iI`

### Usage:

```
USAGE:
    rwfus [FLAGS] [OPTIONS] [--] [DIRECTORY]...

FLAGS:
    -h, --help          Show this help text, then exit
    -v, --version       Show the version number, then exit

    -i, --install*      Install Rwfus
    -u, --update*       Re-generate systemd mount files, without touching data
    -r, --remove*       Remove ALL FILES AND DIRECTORIES associated with Rwfus

    -e, --enable*       Activate Rwfus's overlay mounts
    -d, --disable*      Deactivate Rwfus's overlay mounts
    -s, --status        Get the status of Rwfus's overlay mounts

        --mount*        Mount Rwfus's disk image
        --umount*       Unmount Rwfus's disk image

    -I, --install-bin*  Put rwfus into a [...]/usr/local/bin folder
    -R, --remove-bin*   Remove Rwfus from a [...]/usr/local/bin folder

    -t, --test          Use fake directory targets when performing operations
    -g, --gen-config    Generate a sample config file, which you can use to customize your install

    * flags marked with a star require root, unless the --test flag is set.

    OPTIONS:
    -l, --logfile <path>    Specify the location of Rwfus's log file
                                Default: /tmp/rwfus.XXXX.log (where X is random)
    -c, --config <path>     Specify a configuration file to use
                                Default: /opt/rwfus/

ARGS:
    <DIRECTORY>...          List of directories to create overlays for
                                Defaults: /usr /etc/pacman.d /var/lib/pacman /var/cache/pacman
```

#### Examples:

> `rwfus`: Get status

> `rwfus --install`: Install Rwfus

> `rwfus --update`: Update Rwfus's scripts

> `rwfus --remove`: Remove Rwfus, including the pacman keyring and all installed pacman packages

> `rwfus --gen-config`: Generate a sample config file in your present working directory

> `rwfus --config ./rwfus.conf`: Use a config file called `rwfus.conf` when setting up Rwfus

> `rwfus --install-bin`: Install Rwfus into the overlaid /usr/local/bin folder, so you can configure Rwfus from anywhere!

> `rwfus --install --install-bin` will do the above, with a fresh install, in a single command!

### Pacman Setup, once complete:
```
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Sy
```
Warning: Due to the way Valve's firmware updates work, doing `pacman -S[y[y]]u` at any time will lead to complications when the next firmware update is installed. I highly advise avoiding `-Su`, `-Syu`, and `-Syyu` altogether on a Steam Deck with read-only rootfs.
