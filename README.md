<h1 align="left">
  <a href="https://github.com/ChaoticSi1ence/LenovoLegionLinux" target="_blank">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/johnfanv2/LenovoLegionLinux/HEAD/doc/assets/legion_logo_dark.svg">
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/johnfanv2/LenovoLegionLinux/HEAD/doc/assets/legion_logo_light.svg">
      <img alt="LenovoLegionLinux" src="https://raw.githubusercontent.com/johnfanv2/LenovoLegionLinux/HEAD/doc/assets/legion_logo_dark.svg" height="50" style="max-width: 100%;">
    </picture>
  </a>
  <strong>Lenovo Legion Linux Support (Q7CN Fork)</strong>
</h1>

[![Build](https://github.com/ChaoticSi1ence/LenovoLegionLinux/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/ChaoticSi1ence/LenovoLegionLinux/actions/workflows/build.yml)
[![Join Discord](https://img.shields.io/discord/761178912230473768?label=Legion%20Series%20Discord)](https://discord.com/invite/legionseries)
[![Check Reddit](https://img.shields.io/static/v1?label=Reddit&message=LenovoLegion&color=green)](https://www.reddit.com/r/LenovoLegion/)

> **This is a fork of [johnfanv2/LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux).**
> It is optimized and tested for the **Lenovo Legion Pro 7 16IAX10H** (Q7CN, EC 0x5508) but includes
> ~110 bug fixes across the entire codebase that benefit all supported models. If you have a different
> Legion model, this fork should work for you too — and it may work better than upstream due to the
> bug fixes. For distro-specific packages (AUR, Fedora COPR, NixOS, etc.), see the
> [upstream project](https://github.com/johnfanv2/LenovoLegionLinux).

**This project is not affiliated with Lenovo. Use at your own risk.**

---

## Table of Contents

- [What's New in This Fork](#whats-new-in-this-fork)
- [Tested Hardware](#tested-hardware)
- [Features](#features)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Hardware Test Script](#hardware-test-script)
- [Known Limitations](#known-limitations)
- [FAQ](#faq)
- [Credits](#credits)

---

## What's New in This Fork

### Q7CN Model Support (Legion Pro 7 16IAX10H)

- Full model configuration with **WMI3 access methods** for all hardware interfaces
- **3-fan support**: CPU (fan ID 1), GPU (fan ID 2), Auxiliary (fan ID 4) — non-sequential IDs correctly mapped
- **5 power modes**: Quiet (1), Balanced (2), Performance (3), Custom (255), **Extreme (224/0xE0)**
- Extreme mode validated with live hardware writes

### Safety Mechanisms

- **`wmi_dryrun` module parameter** — gates all WMI writes at the single `wmi_exec_arg` chokepoint.
  When enabled, the driver logs what *would* be written to hardware without actually executing the WMI
  call. This allows full code path validation without risk.

  ```bash
  # Load with dry-run (safe — no hardware writes)
  sudo modprobe legion-laptop wmi_dryrun=1

  # Load for real use
  sudo modprobe legion-laptop
  ```

### Bug Fixes (~110 across 50 files)

These fixes apply to the entire driver, not just Q7CN:

- Fixed NULL dereference in multiple WMI notification handlers
- Fixed `pwm1_mode` hwmon attribute — was hardcoded to EC access, now uses the access_method dispatcher
- Fixed fan curve validation rejecting valid WMI3 values at point 0 (firmware returns non-zero minimum fan speeds)
- Fixed copy-paste GUID bugs in WMI method calls
- Fixed LED `container_of` type mismatches
- Fixed WMI notify race conditions
- Added `wmi_other_method_set_value()` for OtherMethod GUID (method 18)
- Code polish: checkpatch-compliant comments, GUID case consistency, dead code removal

### Build and Test Infrastructure

- **`kernel_module/build-legion-module.sh`** — build, install, blacklist conflicting upstream modules, load — all in one script
- **`tests/test_hardware_q7cn.sh`** — 18-section hardware validation suite with `--wmi-dryrun`, `--test-extreme`, and `--install-blacklist` flags

---

## Tested Hardware

### Primary: Legion Pro 7 16IAX10H (Q7CN)

| Property | Value |
|----------|-------|
| Model | 83F5 |
| BIOS | Q7CN45WW |
| EC ID | 0x5508 |
| CPU | Intel Core Ultra 9 275HX |
| GPU | NVIDIA RTX 5090 Laptop GPU |
| RAM | 32 GB |
| Test Kernel | CachyOS 6.19.3-2-cachyos |
| Test Results | **PASS 46/46** (live), **PASS 56/56** (dry-run), **0 FAILs** |

### Hwmon Interface

| Sensor | Source | Status |
|--------|--------|--------|
| temp1 (CPU) | WMI OtherMethod | Working |
| temp2 (GPU) | WMI OtherMethod | Working |
| temp3 (IC) | WMI OtherMethod | Working |
| fan1 RPM (CPU) | WMI OtherMethod | Working |
| fan2 RPM (GPU) | WMI OtherMethod | Working |
| fan3 RPM (Aux) | WMI OtherMethod | Working |
| Fan curve (10 points, unified) | WMI FanMethod | Read + write working |

### Sysfs Attributes

All readable and writable: `powermode`, `rapidcharge`, `touchpad`, `fan_fullspeed`, `fan_maxspeed`,
`lockfancontroller`, `overdrive`, `gsync`, `winkey`, `igpumode`

### Also Tested: Legion Pro 7 16AFR10H (SMCN)

| Component | Detail |
|-----------|--------|
| Model | Lenovo Legion Pro 7 16AFR10H (83RU) |
| CPU | AMD Ryzen 9 9955HX |
| GPU | NVIDIA GeForce RTX 5070 Ti Laptop |
| BIOS prefix | SMCN |
| EC | ITE IT5508 (0x5508) |
| Status | Config added, awaiting user verification |

AMD variant of the Gen 10 Legion Pro 7 (same chassis as Q7CN). Reported by
[gluceri](https://github.com/johnfanv2/LenovoLegionLinux/issues/385) on upstream.
EC direct reads give wrong values on this platform; WMI3 access methods required
(handled automatically by the `model_smcn` config).

### Other Supported Models

All models supported by the [upstream project](https://github.com/johnfanv2/LenovoLegionLinux#pushpin-confirmed-compatible-models)
should also work with this fork. The ~110 bug fixes apply to the shared codebase and may improve
stability on other hardware. If you test this fork on a different model, please open an issue with
your results.

---

## Features

Lenovo Legion Linux is the Linux alternative to Lenovo Vantage / Legion Zone (Windows only).
It provides a kernel module with standard Linux interfaces (sysfs, debugfs, hwmon) and a Python
GUI/CLI for configuration.

- **Fan curve control** — up to 10 points using CPU, GPU, and IC temperatures simultaneously.
  Set speed (RPM or PWM), acceleration/deceleration, and hysteresis per point. Allows speeds
  below 1600 RPM for quiet operation.
- **Power mode switching** — Quiet, Balanced, Performance, Custom, and Extreme modes via software.
  Integrates with `power-profiles-daemon` and desktop environment settings.
- **Temperature and fan monitoring** — CPU, GPU, IC temperatures and fan RPMs via standard hwmon,
  compatible with tools like `sensors`, `psensor`, and any hwmon-aware application.
- **Battery conservation mode** — keep battery at ~60% when on AC to prolong battery life.
- **Fn lock** — use special functions on F1-F12 without holding Fn.
- **Touchpad toggle**, **camera power**, **USB charging**, **display overdrive**, **G-Sync toggle**
- **Y-Logo and IO-Port LED control** (model dependent)
- **Fan controller lock/unlock** — freeze fan speed at current level
- **Mini fan curve** — automatic low-noise curve when temperatures stay cool (model dependent)
- **Automatic fan profile switching** via the `legiond` daemon based on power mode and AC/battery state

<p align="center">
    <img height="300" style="float: center;" src="doc/assets/fancurve_gui.jpg" alt="fancurve">
    <img height="300" style="float: center;" src="doc/assets/psensor.png" alt="psensor">
    <img height="300" style="float: center;" src="doc/assets/powermode.png" alt="powermode">
</p>

---

## Quick Start

### Requirements

You need standard kernel build tools: `make`, `gcc` or `clang`, and `linux-headers` for your
running kernel. For the Python GUI, you also need `python3-pyqt6`, `python3-yaml`, and
`python3-argcomplete`.

Distribution-specific dependency scripts are in [`deploy/dependencies/`](deploy/dependencies/).
For example, on Ubuntu 24.04:

```bash
./deploy/dependencies/install_dependencies_ubuntu_24_04.sh
./deploy/dependencies/install_development_dependencies_ubuntu_24_04.sh
```

On Arch-based distributions:

```bash
sudo pacman -S linux-headers base-devel lm_sensors python-pyqt6 python-yaml python-argcomplete
```

### Build and Install

**Option 1: Build script (recommended)**

The build script handles building, installing, blacklisting conflicting upstream modules, and
loading the module:

```bash
git clone https://github.com/ChaoticSi1ence/LenovoLegionLinux.git
cd LenovoLegionLinux
sudo bash kernel_module/build-legion-module.sh
```

**Option 2: Manual build**

```bash
git clone https://github.com/ChaoticSi1ence/LenovoLegionLinux.git
cd LenovoLegionLinux/kernel_module
make
sudo make install
sudo depmod -a
sudo modprobe legion-laptop
```

You must rebuild and reinstall after each kernel update. For automatic rebuilds, consider
[DKMS](https://github.com/johnfanv2/LenovoLegionLinux#installing-via-dkms) (see upstream docs).

### Blacklisting Conflicting Modules

On kernels 6.12+, three upstream `lenovo-wmi` modules conflict with `legion-laptop`. The build
script handles this automatically. To do it manually:

```bash
cat <<'EOF' | sudo tee /etc/modprobe.d/blacklist-lenovo-wmi.conf
blacklist lenovo_wmi_gamezone
blacklist lenovo_wmi_other
blacklist lenovo_wmi_events
EOF
```

Other `lenovo-wmi` modules (`capdata01`, `helpers`, `hotkey_utilities`, `camera`) are safe and
do not need to be blacklisted.

### Verify Installation

```bash
# Check the module loaded
sudo dmesg | grep legion

# Expected: "legion_laptop loaded for this device"

# Check sensors
sensors

# Expected output includes:
#   legion_hwmon-isa-0000
#   Fan 1:        1800 RPM
#   Fan 2:        1900 RPM
#   Fan 3:        2500 RPM
#   CPU Temperature:  +57.0°C
#   GPU Temperature:  +48.0°C
#   IC Temperature:   +40.0°C

# Check fan curve (debug)
sudo cat /sys/kernel/debug/legion/fancurve
```

---

## Usage

### Temperature and Fan Monitoring

Temperatures and fan speeds are exposed via standard hwmon and work with any monitoring tool:

```bash
sensors                    # Command-line
psensor                    # GUI (install separately)
```

### Power Mode

The current power mode can be read and changed via sysfs:

```bash
# Read current mode
cat /sys/bus/platform/drivers/legion/PNP0C09:00/powermode
# Values: 1=Quiet, 2=Balanced, 3=Performance, 255=Custom, 224=Extreme

# Change mode (as root)
echo 3 | sudo tee /sys/bus/platform/drivers/legion/PNP0C09:00/powermode
```

You can also toggle modes with **Fn+Q** on the keyboard, or use `power-profiles-daemon` /
`powerprofilesctl` if `enable_platformprofile=true` is set.

To set the module parameter permanently:

```bash
echo 'options legion-laptop enable_platformprofile=true' | sudo tee /etc/modprobe.d/legion-laptop.conf
```

### Fan Curve

The fan curve is controlled through standard hwmon attributes:

```bash
HWMON=/sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/hwmon/hwmon*

# Read point 1 speed for fan 1
cat $HWMON/pwm1_auto_point1_pwm

# Set point 2 speed for fan 1 (~1500 RPM)
echo 38 | sudo tee $HWMON/pwm1_auto_point2_pwm

# Read the full curve (debug view)
sudo cat /sys/kernel/debug/legion/fancurve
```

Changing power mode with Fn+Q or restarting resets the fan curve to firmware defaults.

### GUI and CLI

The Python GUI provides a graphical interface for fan curve editing, power mode switching,
and all other features:

```bash
sudo python3 python/legion_linux/legion_linux/legion_gui.py
```

The CLI provides the same functionality for scripting:

```bash
sudo python3 python/legion_linux/legion_linux/legion_cli.py --help
```

### Other Features

| Feature | Sysfs Path | Notes |
|---------|-----------|-------|
| Battery conservation | `ideapad/conservation_mode` | Keep battery at ~60% on AC |
| Fn lock | `ideapad/fn_lock` | Also toggled with Fn+Esc |
| Touchpad | `legion/touchpad` | Also toggled with Fn+F10 |
| Camera power | `ideapad/camera_power` | |
| USB charging | `ideapad/usb_charging` | Always-on USB when lid closed |
| Display overdrive | `legion/overdrive` | |
| G-Sync / Hybrid mode | `legion/gsync` | |
| Windows key | `legion/winkey` | |
| Fan full speed | `legion/fan_fullspeed` | Dust cleaning mode |

Note: `conservation_mode`, `fn_lock`, `camera_power`, and `usb_charging` are provided by the
`ideapad-laptop` module, not `legion-laptop`.

### Lenovo Legion Support Daemon (legiond)

The `legiond` daemon automatically switches fan profiles based on power mode and AC/battery state.
See [`extra/service/legiond/README.org`](extra/service/legiond/README.org) for configuration.

---

## Hardware Test Script

A comprehensive test script is provided for Q7CN hardware validation. It can also serve as a
template for testing other models.

```bash
# Safe test — dry-run mode (no hardware writes)
sudo bash tests/test_hardware_q7cn.sh --wmi-dryrun

# Full test with live extreme mode write
sudo bash tests/test_hardware_q7cn.sh --test-extreme

# Install upstream module blacklist
sudo bash tests/test_hardware_q7cn.sh --install-blacklist

# Skip build step (use previously built module)
sudo bash tests/test_hardware_q7cn.sh --skip-build --wmi-dryrun
```

The test script covers 18 sections: system info, module build/load, sensor readings, fan curve
attributes, power mode read/write, WMI GUID presence, debugfs, and dry-run write validation.

---

## Known Limitations

### Q7CN Specific

- `fan1_target` reports 9600 RPM while actual fan speed is ~1800 RPM — investigation deferred
- `lockfancontroller` write path bypasses the access_method dispatcher and always hits EC portio
- IO-Port LED (light_id 5) — firmware returns zeroed buffer from WMAF, no handler present
- Keyboard backlight is firmware-loaded via USB — no WMI control available
- `minifancurve` register returns 0 — not supported on WMI3 hardware

### General

- Fan curve size cannot be changed (10 points in Performance, 9 otherwise). Disable unused
  points by setting temperature limits to 127.
- The fan curve resets when changing power mode (Fn+Q) or restarting.
- The module must be rebuilt after each kernel update (unless using DKMS).

---

## FAQ

**The module doesn't load — "not in allowlist"**

Your laptop model is not recognized. Check `sudo dmesg | grep legion` for the exact message.
You can force-load with `sudo modprobe legion-laptop force=1` to test, and open an issue with
your model details.

**Sensors show 0 RPM or 0 temperature**

The module may not have loaded correctly, or your model uses a different access method. Check
`sudo dmesg | grep legion` for errors. GPU temperature may read 0 when the dGPU is in deep sleep.

**Fans never stop or are always loud**

Check the IC temperature limit in your fan curve — many models ship with a low IC temperature
limit that keeps fans running. Increase the temperature limits for the lowest fan curve point.

**Fans don't respond to temperature changes**

The fan controller may be locked. Check `cat /sys/bus/platform/drivers/legion/PNP0C09:00/lockfancontroller`.
Write `0` to unlock it. A BIOS update/reset can also fix this.

**It stopped working after a kernel update**

Rebuild and reinstall the module. See [Build and Install](#build-and-install). Consider using
DKMS for automatic rebuilds.

**USB-C PD charging doesn't work or drops to trickle charge (Gen 10)**

The Lenovo EC firmware's UCSI PPM (USB Type-C Connector System software Interface) implementation
is broken on Gen 10 models (Q7CN, SMCN, and likely others). The kernel's `ucsi_acpi` driver queries
this broken mailbox and actively interferes with Power Delivery negotiation. Symptoms: charger
connects briefly at full wattage, then drops to ~1W within 30-60 seconds.

Fix: blacklist the `ucsi_acpi` module:

```bash
echo "blacklist ucsi_acpi" | sudo tee /etc/modprobe.d/blacklist-ucsi.conf
sudo reboot
```

You lose `/sys/class/typec/` sysfs reporting, but it was returning garbage data anyway. The EC's PD
controller negotiates correctly on its own without the kernel driver interfering. This is the same
class of bug as ThinkPad T14 Gen 5
([fwupd/firmware-lenovo#521](https://github.com/fwupd/firmware-lenovo/issues/521), Lenovo tracker
LO-4169). Discovered by [alstergee](https://github.com/johnfanv2/LenovoLegionLinux/issues/385).

---

## Credits

### Upstream Project

This fork is based on [LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux) by
[johnfanv2](https://github.com/johnfanv2). Thank you for creating and maintaining the original
project that made Linux support for Legion laptops possible.

### Original Contributors

- [SmokelessCPU](https://github.com/SmokelessCPUv2) — reverse engineering the EC firmware and
  finding the direct IO control method
- [FanFella](https://github.com/SmokelessCPUv2) — finding the address to lock/unlock the fan controller
- [Bartosz Cichecki](https://github.com/BartoszCichecki) — creating
  [LenovoLegionToolkit](https://github.com/BartoszCichecki/LenovoLegionToolkit) for Windows
- [0x1F9F1](https://github.com/0x1F9F1) — reverse engineering the fan curve in EC firmware and
  creating [LegionFanControl](https://github.com/0x1F9F1/LegionFanControl)
- [ViRb3](https://github.com/ViRb3) — creating [Lenovo Controller](https://github.com/ViRb3/LenovoController)
- [Luke Cama](https://www.legionfancontrol.com/) — [LegionFanControl](https://www.legionfancontrol.com/)
- David Woodhouse — the [ideapad-laptop](https://github.com/torvalds/linux/blob/master/drivers/platform/x86/ideapad-laptop.c)
  kernel driver

### Community Tools

- [PlasmaVantage](https://gitlab.com/Scias/plasmavantage) — KDE Plasma widget for LenovoLegionLinux
- [CinnamonVantage](https://github.com/linuxmint/cinnamon-spices-applets/tree/master/cinnamonvantage%40garlayntoji) — Cinnamon applet for LenovoLegionLinux

---

## Legal

Reference to any Lenovo products, services, processes, or other information and/or use of Lenovo Trademarks does not constitute or imply endorsement, sponsorship, or recommendation thereof by Lenovo.

The use of Lenovo, Lenovo Legion, Yoga, IdeaPad or other trademarks within this repository and associated tools is only to provide a recognisable identifier to users to enable them to associate that these tools will work with Lenovo laptops.

License: [GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
