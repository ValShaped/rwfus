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

Run `rwfus --help` to see every option

### Pacman Setup, once complete:
```
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Su
```
