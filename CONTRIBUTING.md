# Contributing

This is a fork of [johnfanv2/LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux),
optimized for the Legion Pro 7 16IAX10H (Q7CN) but designed to work with all supported models.

## Reporting Issues

- Include your exact laptop model, BIOS version, and kernel version.
- Include the output of `sudo dmesg | grep legion` and `sensors`.
- If possible, run the hardware test script and attach the log:
  ```bash
  sudo bash tests/test_hardware_q7cn.sh --wmi-dryrun 2>&1 | tee /tmp/legion-test.log
  ```

## Adding Support for a New Model

1. Identify your model's BIOS prefix (e.g., `Q7CN`, `GKCN`, `N0CN`) from `dmidecode -s bios-version`.
2. Add a DMI match entry and model config in `kernel_module/legion-laptop.c`.
   Use `model_q7cn` as a reference for WMI3-based models.
3. Build and test with `wmi_dryrun=1` first:
   ```bash
   cd kernel_module && make
   sudo insmod legion-laptop.ko wmi_dryrun=1
   ```
4. Open an issue or PR with your test results.

## Code Style

- Follow the Linux kernel coding style.
- Use C block comments (`/* */`) not C++ style (`//`) for multi-line comments.
- Run `make allWarn` to check for extra warnings before submitting.

## Building

See [README.md](README.md#quick-start) for build instructions.
