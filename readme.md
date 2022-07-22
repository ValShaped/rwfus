## Rwfus: Read-Write OverlayFS for your Steam Deck!
###### Or anything else with systemd and a read-only filesystem
---

Generator for overlay mount systemd unit files

By default, mounts /usr /etc/pacman.d /var/lib/pacman and /var/cache/pacman, so you can get pacman working properly

### Installation:

1. `git clone https://github.com/ValShaped/rwfus.git`
2. `cd rwfus`
3. `./setup.sh`
    - Step 1 generates all the configs and directory structure, in a temp folder located alongside the script.
    - Step 2 copies the systemd unit files to /etc/systemd/system
    - Step 3 copies the new upper and work directories to /home/.rwfus
    - Step 4 activates all the newly generated unit files

### Pacman Setup, once complete:
```
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Su
```
