# Sovol SV07 — Hackspace Printer Config

Config backup and setup notes for the Hacker Embassy Yerevan Sovol SV07, running on an MKS Klipad50 board. This repo is a mirror of `~/printer_data/config/` (and related files) pulled from the printer host via `rsync`.

## Host: 10.13.37.151 (`mks@10.13.37.151`)

Pull the latest config from the printer:

```bash
rsync -avz --progress mks@10.13.37.151:~/printer_data/config/ ./config/
```

Or the full `printer_data` tree (moonraker.conf, KlipperScreen config, etc.):

```bash
rsync -avz --progress mks@10.13.37.151:~/printer_data/ ./printer_data/
```

`printer_data/logs/` and `printer_data/gcodes/` are git-ignored — large/binary, not config.

---

## OS / Firmware

The printer originally shipped on Sovol's factory image: Armbian, Debian **Buster**, on the MKS Klipad50 (an MKS-PI derivative board). That image is a dead end — Buster's repos are EOL for this board and no new packages can be installed against it.

We replaced it with **torte71's "Sovolized" Armbian image**, a community-maintained rebuild specifically for Sovol SV06/SV07 + Klipad50/MKS-PI boards, currently on **Debian 13 (Trixie)**, kernel 6.12.41:

- Release page: https://github.com/torte71/mksklipad50-klipper-images/releases
- Image details / changelog: https://torte71.github.io/tmteststuff/image.html
- How the image is built (reference, not required reading): https://torte71.github.io/tmteststuff/rebuilding.html
- Background on why Sovol's Buster image is a dead end: https://torte71.github.io/InsideSovolKlipperScreen/armbian-mkspi-setup-v24-2.md

The image ships with the whole stack preinstalled via KIAUH — no manual KIAUH setup needed:

| Component | Version (as shipped) |
|---|---|
| KIAUH | preinstalled |
| Klipper | v0.13.0-213 |
| Moonraker | v0.9.3-102 |
| Mainsail | v2.14.0 |
| Fluidd | v1.34.3 |
| KlipperScreen | v0.4.6-11 |
| Crowsnest | v4.1.16-1 |
| Makerbase/Sovol extras | `makerbase-beep-service`, `makerbase-automount-service`, `makerbase-soft-shutdown-service`, PLR (powerloss recovery) |

### MCU firmware

Flashing the host image is not enough — the physical printer mainboard MCU needs its own firmware flash or Klipper won't connect (version mismatch error). The image ships a precompiled `klipper*.bin` in `/root` on the eMMC for this.

**Process** (not a same-device copy — it goes host → SD card → mainboard):
1. Copy the `.bin` off the eMMC (SCP, or via Mainsail/Fluidd file browser).
2. Rename it — must end in `.bin`, and must be a **new filename** not previously used (the board remembers flashed filenames and won't re-flash a repeat).
3. Put it on a separate FAT32 SD card, insert into the **mainboard's own SD slot** (on the SV07 this means removing the front panel — it's not the eMMC/host slot).
4. Power-cycle and wait up to ~5 minutes for the bootloader to auto-flash.
5. Confirm in Mainsail's Machine panel that `mcu`, `mcu-rpi`, and host Klipper versions all match.

Reference: https://torte71.github.io/InsideSovolKlipperScreen/updating_klipper.html
Beginner-friendly walkthrough: https://github.com/vasyl83/SV07update

---

## UI / Usability

- **Print preview thumbnails** — working, showing on KlipperScreen and Fluidd.
- **Bed mesh** — working.

---

## Bed Meshing / Purge — KAMP

Adaptive bed meshing and purge are handled by **KAMP (Klipper Adaptive Meshing & Purging)**:

- Repo: https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging
- Only meshes/purges the area actually used by the print, instead of the full bed — faster print starts, denser mesh where it matters, less probe wear.

Install:
```bash
cd ~
git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
ln -s ~/Klipper-Adaptive-Meshing-Purging/Configuration ~/printer_data/config/KAMP
cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg ~/printer_data/config/KAMP_Settings.cfg
```

Add to `moonraker.conf` for update-manager tracking:
```ini
[update_manager Klipper-Adaptive-Meshing-Purging]
type: git_repo
channel: dev
path: ~/Klipper-Adaptive-Meshing-Purging
origin: https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
managed_services: klipper
primary_branch: main
```

`printer.cfg` must `[include KAMP_Settings.cfg]` near the top, and `[exclude_object]` must be enabled. Slicer must have **Label Objects / Exclude Objects** turned on (OrcaSlicer: Others tab).

**Status:** working — purge sequence now correctly runs bed mesh compensation *after* the purge, before the actual print starts (previously it purged but skipped applying the mesh afterward).

---

## Macros / G-code

- **`PRINT_START`** — fixed.
- **Purge → mesh ordering** — fixed (see KAMP section above).
- **Wipe command** — not yet implemented. Blocked on picking/mounting physical wiper hardware (brush vs. silicone wiper vs. scrub plate) before the macro can be written.
- **Y axis extension after homing** — open.

---

## Open Items

- [ ] Wipe hardware selection + mount point, then wipe macro
- [ ] Extend Y axis travel in after-homing macro
- [ ] Repair accelerometer cable → run input shaping (`SHAPER_CALIBRATE`)
- [ ] Confirm/finish basic Z offset + bed leveling tuning
- [ ] Belt tension check
- [ ] Pressure advance tuning
- [ ] Misc "button up" fixes (loose ends from initial bring-up)
- [ ] MGN9H linear rail conversion (hardware upgrade, longer-term)

---

## Useful Links

- torte71's Sovolized image releases: https://github.com/torte71/mksklipad50-klipper-images/releases
- torte71's "Inside Sovol KlipperScreen" resource hub: https://torte71.github.io/InsideSovolKlipperScreen/armbian_images.html
- Vasyl's beginner-friendly SV07 update guide: https://github.com/vasyl83/SV07update
- KAMP: https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging
- KIAUH: https://github.com/dw-0/kiauh
