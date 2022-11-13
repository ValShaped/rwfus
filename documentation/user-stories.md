
> where UIC :: "User issues command"
> Substitute all commands for their shortopt/longopt versions, where applicable

## H: Helptext
| ID   | Milestone | Name    | Action | Result |
|------|:---------:|---------|:-------|:-------|
| H1.0 | v0.2.0    | Help    | UIC `rwfus -h`  | Helptext is printed explaining usage.    |
| H2.0 | v0.3.0    | Version | UIC `rwfus -v`  | Name and version information is printed. |

## C: Options
| ID   | Milestone | Name                    | Action | Result |
|------|:---------:|-------------------------|:-------|:-------|
| C1.0 | v0.3.0    | Load Configuration      | UIC `rwfus -c $config_file -*` | Load `$config_file` before performing the action `-*`|
| C2.0 | v0.3.0    | Change Logfile Location | UIC `rwfus -l $log_file -*` | Change logfile location to that specified in $log_file before performing the action `-*` |

## M: Service Management
| ID   | Milestone | Name    | Action | Result |
|------|:---------:|---------|:-------|:-------|
| M1.0 | v0.2.0    | Install | UIC `rwfus -i` | The `rwfusd` service is installed and started. Pacman is initialized. |
| M2.0 | v0.2.0    | Update  | UIC `rwfus -u` | The service is stopped, updated, and started. Status is printed for the user. |
| M3.0 | v0.2.0    | Remove  | UIC `rwfus -r` | The user is prompted to confirm removal. The service `rwfusd` is stopped and removed. All Rwfus state is wiped, except for `$Config`. |
| M3.1 | v0.3.0    | Remove  | UIC `rwfus -r please` | The `rwfusd` service is stopped and removed. All Rwfus state is wiped, except for `$Config`. |

## S: Status / Activation
| ID   | Milestone | Name    | Action | Result |
|------|:---------:|---------|:-------|:-------|
| S1.0 | v0.2.0    | Status  | UIC `rwfus -s` | Status is printed for the user. Disk partition information is printed for the user. |
| S2.0 | v0.2.0    | Disable | UIC `rwfus -d` | The `rwfusd` service is disabled.   Status is printed for the user. |
| S3.0 | v0.2.0    | Enable  | UIC `rwfus -e` | The `rwfusd` service is re-enabled. Status is printed for the user. |

## D: Disk Image Management
| ID   | Milestone |  Name        | Action | Result |
|------|:---------:|--------------|:-------|:-------|
| D1.0 | v0.4.0    | Mount Disk   | UIC `rwfus --mount` | The `$Disk_Image` is mounted at `$Mount_Directory` |
| D2.0 | v0.4.0    | Unmount Disk | UIC `rwfus --umount`| The `$Disk_Image` is unmounted |
| D3.0 | v0.4.0    | Backup Disk  | UIC `rwfus --backup $destination`| `rwfusd` is stopped. The `$Disk_Image` is unmounted, copied to `$destination`. `rwfusd` is restarted, if previously stopped. |
| D4.0 | v0.4.0    | Restore Disk | UIC `rwfus --restore $source`    | `rwfusd` is stopped. The `$Disk_Image` is unmounted, and replaced with `$source`. |

## B: Installation on $PATH
| ID   | Milestone | Name        | Action | Result |
|------|:---------:|-------------|:-------|:-------|
| B1.0 | v0.3.0    | Install Bin | UIC `rwfus -I`  | Since we're targeting Steam Deck, copy all scripts to the SteamOS-Offload /usr/local/bin directory. Unmask and enable SteamOS-Offload: /usr/local/bin |
| B2.0 | v0.3.0    | Remove  Bin | UIC `rwfus -R`  | Since we're targeting Steam Deck, delete all scripts from the SteamOS-Offload /usr/local/bin directory. Disable and mask SteamOS-Offload: /usr/local/bin |

## T: Test Mode and Sample Generation
| ID   | Milestone | Name      | Action | Result |
|------|:---------:|-----------|:-------|:-------|
| T1.0 | v0.3.0    | Test Mode | UIC `rwfus -t*` | A test environment is set up in the pwd. The effects in the test environment are as if the UIC `rwfus -*` for all valid options. Superuser must never be required in Test Mode. |
| T2.0 | v0.3.0    | Generate Sample Config | UIC `rwfus --gen-config` | A default config file `rwfus.conf` is generated in the pwd. |
| T3.0 | v0.4.0    | Generate Sample Service | UIC `rwfus --gen-service` | A service file `rwfusd.sh` is generated in the pwd. |
| T4.0 | v0.4.0    | Generate Sample Disk | UIC `rwfus --gen-disk` | An empty, partitionless, btrfs-formatted disk image `rwfus.btrfs` is generated in the pwd. |
