## Rwfus: Read-Write OverlayFS for your Steam Deck!
###### Or anything else with systemd and a read-only filesystem
---

Generator for overlay mount systemd unit files

By default, mounts /usr /etc/pacman.d /var/lib/pacman and /var/cache/pacman, so you can get pacman working properly

### Compatibility warning

The Steam Deck Recovery Image (and possibly newer factory installs) will reformat the home partition on your Deck to ext4 *with the `-O casefold` flag*, which enables case-folding support. Case-folding is *not supported* by the overlayfs kernel driver, and mounting will fail. 
As of right now, there's no way around this issue without using a nightly build of tune2fs which is capable of disabling `casefold` on ext4. 
In the coming days, I'll be updating Rwfus to check if casefold is enabled.

Case folding was enabled on the filesystem level to speed up games which run through Proton. Windows uses case-insensitive paths by default, and user-mode case-folding is much slower than case-folding in the ext4 kernel driver itself. However, since overlayfs doesn't support it, I can't reasonably support it either.

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
sudo pacman -Sy
```
Warning: Due to the way Valve's firmware updates work, doing `pacman -S[y[y]]u` at any time will lead to complications when the next firmware update is installed. I highly advise avoiding `-Su`, `-Syu`, and `-Syyu` altogether on a Steam Deck with read-only rootfs.
