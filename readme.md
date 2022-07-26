## Rwfus: Read-Write OverlayFS for your Steam Deck!
###### Or anything else with systemd and a read-only filesystem
---

Generator for overlay mount systemd unit files

By default, mounts /usr /etc/pacman.d /var/lib/pacman and /var/cache/pacman, so you can get pacman working properly

### Installation:

1. `git clone https://github.com/ValShaped/rwfus.git`
2. `cd rwfus`
3. `./rwfus`

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

        --install-bin*  Put $0 into the overlayed /usr/local/bin folder
        --remove-bin*   Remove Rwfus from the overlayed /usr/local/bin folder

    -t, --test          Use fake directory targets when performing operations
    -g, --gen-config    Generate a sample config file, which you can use to customize your install

    * flags marked with a star require root, unless the --test flag is set.

    OPTIONS:
    -l, --logfile <path>    Specify the location of Rwfus's log file
    -c, --config <path>     Specify a configuration file to use

ARGS:
    <DIRECTORY>...      List of directories to create overlays for
```

#### Examples:

> `rwfus --install` (or just `rwfus`) to install Rwfus

> `rwfus --update` to update Rwfus's configs

> `rwfus --remove` to remove Rwfus, including the pacman keyring and all installed pacman packages

> `rwfus --gen-config` to generate a sample config file in your present working directory

> `rwfus --config ./rwfus.conf` to use a config file called `rwfus.conf` when setting up Rwfus

> `rwfus --install-bin` to install Rwfus into the overlaid /usr/local/bin folder, so you can configure Rwfus from anywhere!  \
> `rwfus --install --install-bin` will do the above, with a fresh install, in a single command!

### Pacman Setup, once complete:
```
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Su
```
