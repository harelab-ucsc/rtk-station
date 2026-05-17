# rtk-station

Setup and service files for the OASIS RTK base station (portable bucket, Pi-based).
Replaces the previous OpenWRT-based system documented in `infrastructure_doc/rtk_bucket.md`.

## Hardware

- **GNSS receiver**: u-blox ZED module on `/dev/ttyACM0` (USB)
- **Radio**: RFDesign RFD900X2 on `/dev/ttyUSB0` at 57600 baud
- **Computer**: Raspberry Pi, hostname `pi-rtkbucket`
- **Network**: ethernet gets DHCP from whatever network it's on; WiFi AP (`HARELAB-RTK`) runs at `162.198.1.1/24` via hostapd

## How It Works

Three `pygnssutils` components run as systemd services:

| Service | What it does |
|---|---|
| `gnss_server` | Reads `/dev/ttyACM0`, exposes a TCP byte stream on port 50010 |
| `gnss_to_ntrip` | Connects to port 50010, filters RTCM, serves NTRIP on port 2101 (mount point: `pygnssutils`) |
| `gnss_to_rfd900` | Connects to port 50010, filters RTCM, writes to the RFD900x radio |

The ZED module must be configured to:
- Output RTCM3 messages: 1005, 1077, 1087, 1097, 1127, 1230
- TMODE3 set to Base Station mode (`SURVEY_IN` or `FIXED`)

## Fresh Install

```bash
# 1. Install pygnssutils
pip install pygnssutils

# 2. Install service files and configure networking
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

## Logs

Each boot creates one directory containing a log file per service:

```
/var/log/rtk-station/
    boot-20250516_120000/
        gnss_server.log
        gnss_to_ntrip.log
        gnss_to_rfd900.log
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

## Managing Services

```bash
# Start
bash launch_files/start_services.sh

# Stop
bash launch_files/stop_services.sh

# Status
systemctl status gnss_server gnss_to_ntrip gnss_to_rfd900 rtk-log-setup

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
