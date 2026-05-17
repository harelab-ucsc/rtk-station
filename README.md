# rtk-station

Setup and service files for the OASIS RTK base station (portable bucket, Pi-based).
Replaces the previous OpenWRT-based system documented in `infrastructure_doc/rtk_bucket.md`.

## Hardware

- **GNSS receiver**: u-blox ZED module on `/dev/ttyACM0` (USB)
- **Radio**: RFDesign RFD900X2 wired to ZED UART (not connected to Pi)
- **Computer**: Raspberry Pi, hostname `pi-rtkbucket`
- **Network**: ethernet gets DHCP from whatever network it's on; WiFi AP (`HARELAB-RTK`) runs at `162.198.1.1/24` via hostapd

## How It Works

Three `pygnssutils` components run as systemd services:

| Service | What it does |
|---|---|
| `gnss_server` | Reads `/dev/ttyACM0`, exposes a TCP byte stream on port 50010 |
| `gnss_to_ntrip` | Connects to port 50010, filters RTCM, serves NTRIP on port 2101 (mount point: `pygnssutils`) |

The RFD900x radio is wired directly to the ZED module's UART — the ZED pushes RTCM to the radio at the hardware level. The Pi does not relay to the radio.

The ZED module must be configured to output RTCM3 messages and run in Survey-In base station mode. `install_services.sh` handles this automatically via `configure_zed.sh`, which sends UBX commands over `/dev/ttyACM0` and saves the config to the ZED's flash. To re-run manually:

```bash
bash launch_files/configure_zed.sh
```

## Fresh Install

```bash
cd launch_files
bash install_services.sh
```

`install_services.sh` copies the `.service` files to `/etc/systemd/system/`, enables them on boot, installs `rtk-log-setup` and `rtk-log-run` to `/usr/local/bin/`, and then calls `install_netconfig.sh` to set the hostname and apply the netplan config.

## Networking

`install_netconfig.sh`:
- Copies `netplan/rtk.yaml` to `/etc/netplan/50-oasis-rtk.yaml` — configures `end0` as DHCP
- Sets hostname to `pi-rtkbucket`

The WiFi AP (`HARELAB-RTK`, `162.198.1.1/24`) is managed separately by hostapd and dnsmasq — netplan leaves `wlan0` alone.

Connect to the Pi:
```bash
ssh rtk-bucket@pi-rtkbucket        # if your DNS/mDNS resolves it
ssh rtk-bucket@<dhcp-assigned-ip>  # check your router or use arp-scan
```
Username: `rtk-bucket`, password: `password`

## NTRIP Connection

Use these credentials on the rover (DJI controller, u-center, etc.):

| Field | Value |
|---|---|
| Host | `172.31.106.2` (via hotspot) or DHCP IP (lab ethernet — check router) |
| Port | `2101` |
| Username | `myuser` |
| Password | `mypassword` |
| Mountpoint | `pygnssutils` |

The NTRIP server only streams data once the ZED has completed survey-in (fix acquired, accuracy < 5m).

## Logs

Each boot creates one directory containing a log file per service:

```
/var/log/rtk-station/
    boot-20250516_120000/
        gnss_server.log
        gnss_to_ntrip.log
        rtk-watchdog.log
    boot-20250516_131500/
        ...
```

`rtk-log-setup.service` runs once before the gnss services, creates the directory, and writes its path to `/run/rtk-station/current-log-dir` (ephemeral tmpfs, cleared each boot). `rtk-log-run` reads that path and appends to `<boot-dir>/<service>.log`.

Pruning limits (enforced at each boot by `rtk-log-setup`):
- **67 boot directories max** — oldest deleted first
- **512 MB total max** — oldest deleted first until under the limit

Read the latest boot's logs:
```bash
LATEST=$(ls -1dt /var/log/rtk-station/boot-* | head -1)
tail -f "$LATEST/gnss_server.log"
ls "$LATEST/"
```

## Watching Logs Live

```bash
bash launch_files/watch_services.sh
```

Opens a tmux session with three panes — one per service — each tailing its latest boot log. If a service hasn't started yet the pane waits until the log appears. Detach with `Ctrl-b d`; re-running the script reattaches.

## Managing Services

```bash
# Start
bash launch_files/start_services.sh

# Stop
bash launch_files/stop_services.sh

# Status
systemctl status gnss_server gnss_to_ntrip rtk-log-setup

# Logs
journalctl -u gnss_server -f
```

## Radio Config (RFD900X2)

The radio runs multipoint firmware. The base station is the master node (Node ID = 1).

Key parameters to verify:
- `S8` Min frequency: `902000`
- `S9` Max frequency: `915000`
- `S10` Number of channels: `51`
- `S24` Node ID: `1` (master)
- Max nodes: set via terminal with `AT&M0=0,16`

Verify raw bytes pass over the radio link before testing RTCM.

See `infrastructure_doc/rtk_bucket.md` and `infrastructure_doc/rfd900x/` for the config file and firmware.
