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

> **This is a fork of [johnfanv2/LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux).**
> It is optimized and tested for the **Lenovo Legion Pro 7 16IAX10H** (Q7CN, EC 0x5508) but includes
> bug fixes across the entire codebase that benefit all supported models. If you have a different
> Legion model, this fork should work for you too. For distro-specific packages (AUR, Fedora COPR,
> NixOS, etc.), see the [upstream project](https://github.com/johnfanv2/LenovoLegionLinux).
> **This fork is clone-and-build only.**

**This project is not affiliated with Lenovo. Use at your own risk.**

---

## What's New in This Fork

### Q7CN Model Support (Legion Pro 7 16IAX10H)

- Full model configuration with **WMI3 access methods** for all hardware interfaces
- **3-fan support**: CPU (fan ID 1), GPU (fan ID 2), Auxiliary (fan ID 4) — non-sequential IDs correctly mapped
- **5 power modes**: Quiet (1), Balanced (2), Performance (3), Custom (255), **Extreme (224/0xE0)**
- **64-byte WMI fan curve buffer** for EC 0x5508 (32-byte crashes the EC)
- **OtherMethod routing** for fan_fullspeed/fan_maxspeed (Gamezone WMI crashes EC 0x5508)
- **FanFullSpeed safety clear** before fan table writes

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

### Bug Fixes

These fixes apply to the entire driver, not just Q7CN:

- Fixed NULL dereference in multiple WMI notification handlers
- Fixed `pwm1_mode` hwmon attribute — was hardcoded to EC access, now uses the access_method dispatcher
- Fixed fan curve validation rejecting valid WMI3 values at point 0 (firmware returns non-zero minimum fan speeds)
- Fixed copy-paste GUID bugs in WMI method calls
- Fixed LED `container_of` type mismatches
- Fixed WMI notify race conditions
- Code polish: checkpatch-compliant comments, GUID case consistency, dead code removal

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
should also work with this fork. Bug fixes apply to the shared codebase and may improve stability
on other hardware. If you test this fork on a different model, please open an issue with your results.

---

## Features

The kernel module (`legion-laptop.ko`) provides standard Linux interfaces (sysfs, debugfs, hwmon)
for hardware control:

- **Fan curve control** — up to 10 points using CPU, GPU, and IC temperatures simultaneously.
  Set speed (RPM or PWM), acceleration/deceleration, and hysteresis per point.
- **Power mode switching** — Quiet, Balanced, Performance, Custom, and Extreme modes.
  Integrates with `power-profiles-daemon` (PPD) so KDE/GNOME power sliders control firmware
  thermal modes directly. See [Power Profile Integration](#power-profile-integration-ppd).
- **Temperature and fan monitoring** — CPU, GPU, IC temperatures and fan RPMs via standard hwmon,
  compatible with `sensors`, `psensor`, and any hwmon-aware application.
- **Battery conservation mode** — keep battery at ~60% when on AC (via `ideapad-laptop`).
- **Touchpad toggle**, **display overdrive**, **G-Sync toggle**, **Windows key lock**
- **Fan controller lock/unlock** — freeze fan speed at current level

---

## Power Profile Integration (PPD)

The driver integrates with [power-profiles-daemon](https://gitlab.freedesktop.org/upower/power-profiles-daemon)
(PPD) to provide **desktop power slider control of firmware thermal modes**. On KDE Plasma and
GNOME, the power profile slider directly switches between Lenovo's firmware modes:

| Desktop Slider | PPD Profile | platform_profile | Firmware Mode |
|----------------|-------------|------------------|---------------|
| Power Save | power-saver | quiet | Quiet (1) |
| Balanced | balanced | balanced | Balanced (2) |
| Performance | performance | performance | Performance (3) |

This is enabled by default (`enable_platformprofile=true`). The build script installs a udev rule
that restarts PPD when the module loads, solving a boot race condition where PPD starts before the
driver is ready.

**How it works:**

```
KDE/GNOME slider
    -> power-profiles-daemon (D-Bus)
        -> /sys/firmware/acpi/platform_profile (kernel)
            -> legion-laptop driver
                -> WMI firmware call (Quiet/Balanced/Performance)
```

Fn+Q on the keyboard also changes the firmware mode, and the change is reflected back through
platform_profile to PPD and the desktop slider.

**Verify it's working:**

```bash
# Check PPD sees the platform profile driver
powerprofilesctl list
# Should show: PlatformDriver: platform_profile (not "placeholder")

# Check current profile
cat /sys/firmware/acpi/platform_profile

# Change from command line
powerprofilesctl set performance
```

If PPD shows `placeholder` instead of `platform_profile`, ensure the udev rule is installed:

```bash
ls /etc/udev/rules.d/99-legion-ppd-restart.rules
# If missing, re-run: sudo bash kernel_module/build-legion-module.sh
```

---

## Quick Start

### Requirements

You need standard kernel build tools: `make`, `gcc` or `clang`, and `linux-headers` for your
running kernel.

```bash
# Arch/CachyOS
sudo pacman -S linux-headers base-devel lm_sensors
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

You must rebuild and reinstall after each kernel update.

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

The recommended way to switch power modes is through the **desktop power slider** (KDE/GNOME),
which uses PPD and platform_profile. See [Power Profile Integration](#power-profile-integration-ppd).

You can also toggle modes with **Fn+Q** on the keyboard, or use the command line:

```bash
# Via PPD (recommended)
powerprofilesctl set performance

# Via sysfs (direct)
cat /sys/bus/platform/drivers/legion/PNP0C09:00/powermode
# Values: 1=Quiet, 2=Balanced, 3=Performance, 255=Custom, 224=Extreme
echo 3 | sudo tee /sys/bus/platform/drivers/legion/PNP0C09:00/powermode
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

### Other Sysfs Attributes

| Feature | Sysfs Path | Notes |
|---------|-----------|-------|
| Touchpad | `legion/touchpad` | Also toggled with Fn+F10 |
| Display overdrive | `legion/overdrive` | |
| G-Sync / Hybrid mode | `legion/gsync` | |
| Windows key | `legion/winkey` | |
| Fan full speed | `legion/fan_fullspeed` | Dust cleaning mode |
| Fan max speed | `legion/fan_maxspeed` | |
| Rapid charge | `legion/rapidcharge` | |

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
- The module must be rebuilt after each kernel update.

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

Rebuild and reinstall the module. See [Build and Install](#build-and-install).

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

---

## Legal

Reference to any Lenovo products, services, processes, or other information and/or use of Lenovo Trademarks does not constitute or imply endorsement, sponsorship, or recommendation thereof by Lenovo.

The use of Lenovo, Lenovo Legion, Yoga, IdeaPad or other trademarks within this repository and associated tools is only to provide a recognisable identifier to users to enable them to associate that these tools will work with Lenovo laptops.

License: [GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
