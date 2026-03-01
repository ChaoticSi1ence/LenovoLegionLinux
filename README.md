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
- **3 power modes**: Quiet (1), Balanced (2), Performance (3) — fully working via PPD, Fn+Q, and sysfs.
  Extreme (224/0xE0) is available via direct sysfs write only. Custom (255) is **blocked by default**
  (causes hard shutdown on Q7CN/SMCN firmware).
- **22 broken sysfs attributes hidden** — Gamezone, CPU, and GPU WMI methods that are non-functional
  on IT5508 EC are automatically hidden via `is_visible` so only working controls are exposed

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
| Test Kernel | CachyOS 6.19.5-3-cachyos |
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

### Sysfs Attributes (Q7CN Hardware-Tested)

Every exposed attribute has been individually tested on Q7CN hardware. Broken attributes are
automatically hidden by the driver (via `is_visible`), so only working controls appear in sysfs.

| Attribute | Type | Test Result |
|-----------|------|-------------|
| `powermode` | RW | Working — Quiet/Balanced/Performance switching verified |
| `rapidcharge` | RW | Working — toggle 0/1, readback matches |
| `winkey` | RW | Working — toggle 0/1, readback matches |
| `touchpad` | RW | Working — toggle 0/1, readback matches |
| `lockfancontroller` | RW | Working — toggle 0/1, readback matches |
| `aslcodeversion` | RO | Working — returns 17 |
| `isacfitforoc` | RO | Working — returns 1 |
| `issupportcpuoc` | RO | Working — returns 0 (CPU OC not supported) |
| `issupportgpuoc` | RO | Working — returns 5 |

**Hidden (non-functional on IT5508 EC):**

| Attribute | Failure Mode |
|-----------|-------------|
| `fan_fullspeed`, `fan_maxspeed` | WMI call succeeds but EC ignores — fans don't respond |
| `gsync`, `overdrive`, `igpumode` | Writes silently ignored (reads back unchanged) |
| `thermalmode` | Writes fail, reads duplicate `powermode` |
| `powerchargemode` | All writes fail |
| `cpumaxfrequency` | Returns garbage value (353899800) |
| `cpu_oc`, `gpu_oc` | Read fails with -EINVAL |
| `cpu_*_powerlimit` (6 attrs) | Read fails with -EINVAL or returns 0 |
| `gpu_*` (6 attrs) | Read fails with -EINVAL |

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

- **Power mode switching** — Quiet, Balanced, Performance via PPD, Fn+Q, or sysfs.
  Extreme mode available via direct sysfs write. Custom mode (255) is blocked by default on
  Q7CN/SMCN (causes hard shutdown). See [Power Profile Integration](#power-profile-integration-ppd).
- **Temperature and fan monitoring** — CPU, GPU, IC temperatures and fan RPMs via standard hwmon,
  compatible with `sensors`, `psensor`, and any hwmon-aware application.
- **Battery conservation mode** — keep battery at ~55-60% when on AC. Provided by the
  `ideapad-laptop` kernel module (loaded automatically). See [Usage](#battery-and-charging).
- **Rapid charge** — fast-charge the battery. Provided by `legion-laptop`. Mutually exclusive with
  conservation mode. See [Usage](#battery-and-charging).
- **Touchpad toggle**, **Windows key lock**, **fan controller lock/unlock** — see [Usage](#other-controls).
- Note: Display overdrive, G-Sync, and iGPU mode toggles are non-functional on Gen 10 IT5508 EC
  models and are automatically hidden from sysfs. They may work on older models.

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

**Without PPD:**

If you don't use `power-profiles-daemon` (e.g., minimal WM setups, i3, sway without PPD), the
driver still works — you just won't get desktop slider integration. The `platform_profile` sysfs
interface is still available for manual control, and Fn+Q still cycles firmware modes:

```bash
# Manual control without PPD
cat /sys/firmware/acpi/platform_profile_choices    # quiet balanced performance
echo performance | sudo tee /sys/firmware/acpi/platform_profile
```

The udev rule installed by the build script is harmless without PPD (it tries to restart a
service that doesn't exist and silently fails).

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
LEGION=/sys/bus/platform/drivers/legion/PNP0C09:00

# Via PPD (recommended — maps to desktop power slider)
powerprofilesctl set performance    # Performance (3)
powerprofilesctl set balanced       # Balanced (2)
powerprofilesctl set power-saver    # Quiet (1)

# Via sysfs (direct)
cat $LEGION/powermode
echo 1 | sudo tee $LEGION/powermode    # Quiet
echo 2 | sudo tee $LEGION/powermode    # Balanced
echo 3 | sudo tee $LEGION/powermode    # Performance

# Extreme mode (not available via PPD or Fn+Q — direct sysfs only)
echo 224 | sudo tee $LEGION/powermode  # Extreme (0xE0)
```

**Warning:** Custom mode (255) is **blocked by default** on Q7CN/SMCN — it causes an immediate
hard power-off. Do not override the `allow_custom_mode` module parameter unless you have confirmed
your firmware supports it.

### Battery and Charging

The base path for `legion-laptop` attributes:

```bash
LEGION=/sys/bus/platform/drivers/legion/PNP0C09:00
```

**Conservation mode** limits charging to ~55-60% to extend battery lifespan. This is provided by
the `ideapad-laptop` module (loaded automatically on Legion hardware), not `legion-laptop`:

```bash
IDEAPAD=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00

# Read current state (0=off, 1=on)
cat $IDEAPAD/conservation_mode

# Enable — stops charging, caps battery at ~55-60%
echo 1 | sudo tee $IDEAPAD/conservation_mode

# Disable — resumes normal charging to 100%
echo 0 | sudo tee $IDEAPAD/conservation_mode

# Check battery status (should show "Not charging" when conservation is on)
cat /sys/class/power_supply/BAT0/status
```

**Rapid charge** enables fast charging. Provided by `legion-laptop`. Conservation mode and rapid
charge should not be enabled simultaneously — disable one before enabling the other:

```bash
# Read current state (0=off, 1=on)
cat $LEGION/rapidcharge

# Enable rapid charge
echo 1 | sudo tee $LEGION/rapidcharge

# Disable rapid charge
echo 0 | sudo tee $LEGION/rapidcharge
```

### Other Controls

```bash
LEGION=/sys/bus/platform/drivers/legion/PNP0C09:00
```

**Touchpad** — also toggled with Fn+F10:

```bash
cat $LEGION/touchpad              # Read (0=disabled, 1=enabled)
echo 0 | sudo tee $LEGION/touchpad   # Disable
echo 1 | sudo tee $LEGION/touchpad   # Enable
```

**Windows key lock** — disable the Windows/Super key (useful in games):

```bash
cat $LEGION/winkey                # Read (0=disabled, 1=enabled)
echo 0 | sudo tee $LEGION/winkey     # Disable Windows key
echo 1 | sudo tee $LEGION/winkey     # Enable Windows key
```

**Fan controller lock** — freeze fans at their current speed:

```bash
cat $LEGION/lockfancontroller     # Read (0=unlocked, 1=locked)
echo 1 | sudo tee $LEGION/lockfancontroller  # Lock fans at current speed
echo 0 | sudo tee $LEGION/lockfancontroller  # Unlock (return to automatic)
```

Note: On Gen 10 IT5508 models (Q7CN/SMCN), the driver automatically hides 22 non-functional
attributes. See [Tested Hardware](#sysfs-attributes-q7cn-hardware-tested) for the full breakdown.
On older models, additional attributes (overdrive, gsync, igpumode, power limits, etc.) may be
available and functional.

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

The test script covers system info, module build/load, sensor readings, power mode read/write,
WMI GUID presence, debugfs, and dry-run write validation.

---

## Known Limitations

### Q7CN / Gen 10 IT5508

- **Custom power mode (255) causes hard shutdown** — the Q7CN/SMCN firmware does not support
  custom mode. Writing 255 to `powermode` triggers an immediate hard power-off. The driver blocks
  this by default (`custom_powermode_unsafe` flag); override with `allow_custom_mode=1` module param
  at your own risk.
- **22 sysfs attributes are non-functional** on the IT5508 EC and are automatically hidden by the
  driver. This includes fan_fullspeed, fan_maxspeed, gsync, overdrive, igpumode, thermalmode,
  powerchargemode, CPU/GPU power limits, and CPU/GPU OC controls. WMI calls succeed but the EC
  ignores them. See [Tested Hardware](#sysfs-attributes-q7cn-hardware-tested) for the full list.
- `fan1_target` reports 9600 RPM while actual fan speed is ~1800 RPM — investigation deferred
- `lockfancontroller` write path bypasses the access_method dispatcher and always hits EC portio
- IO-Port LED (light_id 5) — firmware returns zeroed buffer from WMAF, no handler present
- Keyboard backlight is firmware-loaded via USB — no WMI control available
### General

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
