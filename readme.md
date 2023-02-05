## Rwfus: Read-Write OverlayFS for your Steam Deck!
---

Like a vinyl couch cover for your filesystem, Rwfus covers your Deck's /usr/ directory (and some others) allowing you to initialize and use pacman (the Arch Linux package manager) on the Steam Deck without losing packages when the next update comes out.

Directories covered in a default installation:
Directory         | Contents
---               | ---
/etc/pacman.d     | `pacman` configuration
/usr              | Programs and libraries
/var/cache/pacman | Package cache
/var/lib/pacman   | Package metadata


### Installation:

1. `git clone https://github.com/ValShaped/rwfus.git`
2. `cd rwfus`
3. `./rwfus -iI`

Then you're all set! Remember to periodically run `pacman -Sy` to update your repos

### Jank warning

Due to the way Valve's firmware updates work, doing `pacman -S[y[y]]u` at any time will lead to complications when the next firmware update is installed. I highly advise avoiding `-Su`, `-Syu`, and `-Syyu` altogether on a Steam Deck with read-only rootfs. It may lead to bad behavior.

Rwfus is, right now, a proof of concept (hence the 0.x version number, and being written in Bash.)
I made it to install a couple user-mode packages (nano-syntax-highlighting and yakuake specifically.)
It is not production-ready software, and in using Rwfus, you accept that I am not liable if your Deck catches fire.

Rwfus will allow you to install *any* package, but not everything will let your Deck survive an update. In particular, `glibc` will crash your Deck after an update, requiring the SteamOS recovery image and some knowledge of Linux and/or Rwfus' internals to fix.

### Usage:

```
USAGE:
    /usr/local/bin/rwfus [FLAGS] [OPTIONS] [--] [DIRECTORY]...

FLAGS:
    -h, --help          Show this help text, then exit
    -v, --version       Show the version number, then exit

    -i, --install*      Install Rwfus
    -u, --update*       Re-generate systemd service files, without touching data
    -r, --remove*       Remove ALL FILES AND DIRECTORIES associated with Rwfus

    -e, --enable*       Activate overlays
    -d, --disable*      Deactivate overlays
    -s, --status        Get the status of the overlay-mounter and disk image

        --mount*        Mount Rwfus's disk image
        --umount*       Unmount Rwfus's disk image

    -I, --install-bin*  Put /usr/local/bin/rwfus into a [...]/usr/local/bin folder
    -R, --remove-bin*   Remove Rwfus from a [...]/usr/local/bin folder

    -t, --test          Use fake directory targets when performing operations
    -g, --gen-config    Generate a sample config file, which you can use to customize your install

    * flags marked with a star require root, unless the --test flag is set.

    OPTIONS:
    -l, --logfile <path>    Specify the location of Rwfus's log file
                                Default: /tmp/rwfus.XXXX.log (where X is random)
    -c, --config <path>     Specify a configuration file to use
                                Default: /opt/rwfus/
        --backup <dest>*    Backup Rwfus's disk image to (file path) <dest>
        --restore <src>*    Restore Rwfus's disk image from (file path) <src>

    * options marked with a star require root, unless the --test flag is set.

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
