# CLAUDE.md — LenovoLegionLinux (Q7CN Fork)

## Project Overview

Linux kernel driver (`legion-laptop.ko`) and userspace tools for Lenovo Legion laptops.
Fork of [johnfanv2/LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux),
optimized for the **Legion Pro 7 16IAX10H** (Q7CN, EC 0x5508) but supports all upstream models.

## Repository Layout

```
kernel_module/
  legion-laptop.c          # Main kernel module (~6500 lines, single-file driver)
  Makefile                 # Kernel module build (auto-detects LLVM/clang)
  build-legion-module.sh   # Build, install, blacklist conflicting modules, load
  dkms.conf                # DKMS packaging config
python/legion_linux/       # Python GUI/CLI tools (legion_gui.py, legion_cli.py, legion.py)
tests/
  test_hardware_q7cn.sh    # 18-section hardware validation suite (--wmi-dryrun, --test-extreme)
  test_kernel_*.sh         # Build/install/reload tests
  test_python_*.sh         # Python package tests
extra/                     # Systemd services, ACPI event handlers, legiond daemon
deploy/                    # Dockerfiles, dependency scripts, package build configs
setmyfancurve.sh           # Example fan curve writer via hwmon sysfs (Q7CN/WMI3 PWM values)
```

## Key Technical Details

- **Access methods**: EC (direct port I/O), WMI (ACPI WMI), WMI3 (newer GUID-based). Q7CN uses WMI3.
- **Fan IDs are non-sequential**: CPU=1, GPU=2, Auxiliary=4 (Q7CN has 3 fans).
- **Power modes**: Quiet(1), Balanced(2), Performance(3), Custom(255), Extreme(224/0xE0).
- **Safety**: `wmi_dryrun=1` module parameter gates WMI writes at `wmi_exec_arg()`. Does not gate ACPI writes (e.g. rapid charge via `exec_sbmc`) or direct EC writes (gated separately by `ec_readonly=1`).
- **Conflicting modules**: `lenovo_wmi_gamezone`, `lenovo_wmi_other`, `lenovo_wmi_events` must be blacklisted.

## Build Commands

```bash
# Build kernel module
cd kernel_module && make

# Build with extra warnings (use before submitting)
cd kernel_module && make allWarn

# Full build + install + load (requires root)
sudo ./kernel_module/build-legion-module.sh

# Build only, don't load
sudo ./kernel_module/build-legion-module.sh --no-load

# Clean build artifacts
cd kernel_module && make clean
```

## Test Commands

```bash
# Hardware test (safe dry-run mode)
sudo bash tests/test_hardware_q7cn.sh --wmi-dryrun

# Hardware test (live, includes extreme mode)
sudo bash tests/test_hardware_q7cn.sh --test-extreme

# Kernel build test
bash tests/test_kernel_build.sh

# Checkpatch style check
bash tests/test_kernel_checkpath.sh
```

## Code Style

- **Linux kernel coding style** — tabs, 80-col soft limit, C block comments (`/* */`).
- `.clang-format` is configured at repo root.
- Run `make allWarn` to catch extra warnings.
- Shell scripts use `set -e` and bash.

## Commit Convention

Commits follow conventional format: `type: description`
- Types: `fix`, `feat`, `chore`, `docs`, `style`, `test`
- Examples from history:
  - `fix: FSTM fan curve header, keyboard backlight, curve validation`
  - `feat: add support for Legion Pro 7 16AFR10H (SMCN, 83RU)`
  - `chore: archive stale files, rewrite setmyfancurve.sh, update CONTRIBUTING`

## Important Warnings

- Never write to hardware WMI without understanding the EC register being targeted.
- Always test new model support with `wmi_dryrun=1` first.
- The driver modifies firmware fan curves and power modes — incorrect values can cause thermal issues.
- `legion-laptop.c` is the single source file for the entire kernel module; changes have broad impact.
