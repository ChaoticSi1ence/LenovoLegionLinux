#!/bin/bash
set -eu

# Legion Fan Curve Example Script
#
# Sets a custom fan curve via hwmon sysfs attributes. Edit the values below
# to create your own fan curve. Run as root.
#
# Notes:
#   - The fan curve has up to 10 points (Performance mode) or 9 (other modes).
#   - On WMI3 hardware (Q7CN, etc.) the fan curve is UNIFIED — pwm1 (speed1)
#     controls all fans. pwm2 values are ignored by firmware but must still
#     be written to satisfy the driver's write-back validation.
#   - Point 1 speed does NOT have to be 0. WMI3 firmware returns non-zero
#     minimum fan speeds (e.g. 2% PWM) at the lowest point.
#   - Changing power mode (Fn+Q) or restarting resets the curve to defaults.
#   - Values are in PWM (0-255). Approximate RPM mapping depends on hardware.
#
# Usage:
#   sudo ./setmyfancurve.sh
#
# To restore defaults, press Fn+Q to toggle power mode.

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must run as root (sudo)." >&2
    exit 1
fi

trap 'echo ""; echo "WARNING: Script interrupted. Fan curve may be incomplete." >&2; echo "Press Fn+Q to reset fan curve to defaults." >&2' INT TERM

echo "=== Legion Fan Curve Writer ==="
echo ""

# Detect system info
if command -v dmidecode &>/dev/null; then
    echo "Model: $(dmidecode -s system-version 2>/dev/null || echo 'unknown')"
    echo "BIOS:  $(dmidecode -s bios-version 2>/dev/null || echo 'unknown')"
    echo ""
fi

# Find the hwmon directory for legion_hwmon
HWMON_DIR=""
for d in /sys/class/hwmon/hwmon*; do
    NAME=$(cat "$d/name" 2>/dev/null || true)
    if [ "$NAME" = "legion" ] || [ "$NAME" = "legion_hwmon" ]; then
        HWMON_DIR="$d"
        break
    fi
done

if [ -z "$HWMON_DIR" ]; then
    # Fallback: try the module sysfs path
    HWMON_DIR=$(find /sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/hwmon -mindepth 1 -maxdepth 1 -name "hwmon*" 2>/dev/null | head -1)
fi

if [ -z "$HWMON_DIR" ]; then
    echo "ERROR: Cannot find legion hwmon directory."
    echo "Is the legion-laptop module loaded?"
    exit 1
fi

echo "Using hwmon: $HWMON_DIR"
echo ""

# Helper function to write a value and report status
write_val() {
    local file="$HWMON_DIR/$1"
    local val="$2"
    if [ -f "$file" ]; then
        echo "$val" > "$file" 2>&1 && return 0
        echo "  WARN: Failed to write $val to $1"
        return 1
    else
        echo "  SKIP: $1 not found"
        return 0
    fi
}

# ============================================================================
# Fan speed (PWM) per point — EDIT THESE VALUES
# ============================================================================
# pwm1 = unified fan speed (controls all fans on WMI3 hardware)
# pwm2 = second fan speed (EC-based hardware only; ignored on WMI3)
#
# Values are 0-255 PWM. On WMI3 hardware these are percent-based internally:
#   PWM ~5 = 2%, PWM ~13 = 5%, PWM ~25 = 10%, PWM ~51 = 20%, etc.

echo "Setting fan speeds..."
write_val pwm1_auto_point1_pwm  5     # Point 1: ~2% (minimum spin)
write_val pwm1_auto_point2_pwm  25    # Point 2: ~10%
write_val pwm1_auto_point3_pwm  40    # Point 3: ~16%
write_val pwm1_auto_point4_pwm  55    # Point 4: ~22%
write_val pwm1_auto_point5_pwm  75    # Point 5: ~29%
write_val pwm1_auto_point6_pwm  100   # Point 6: ~39%
write_val pwm1_auto_point7_pwm  130   # Point 7: ~51%
write_val pwm1_auto_point8_pwm  170   # Point 8: ~67%
write_val pwm1_auto_point9_pwm  210   # Point 9: ~82%
write_val pwm1_auto_point10_pwm 255   # Point 10: 100% (max)

# Mirror for pwm2 (only effective on EC-based dual-fan hardware)
write_val pwm2_auto_point1_pwm  5
write_val pwm2_auto_point2_pwm  25
write_val pwm2_auto_point3_pwm  40
write_val pwm2_auto_point4_pwm  55
write_val pwm2_auto_point5_pwm  75
write_val pwm2_auto_point6_pwm  100
write_val pwm2_auto_point7_pwm  130
write_val pwm2_auto_point8_pwm  170
write_val pwm2_auto_point9_pwm  210
write_val pwm2_auto_point10_pwm 255

# ============================================================================
# CPU temperature thresholds (degrees C) — EDIT THESE VALUES
# ============================================================================
# temp = upper threshold (go to next point if above)
# temp_hyst = lower threshold (stay at this point until temp drops below)

echo "Setting CPU temp thresholds..."
write_val pwm1_auto_point1_temp       45
write_val pwm1_auto_point1_temp_hyst  0
write_val pwm1_auto_point2_temp       55
write_val pwm1_auto_point2_temp_hyst  42
write_val pwm1_auto_point3_temp       60
write_val pwm1_auto_point3_temp_hyst  52
write_val pwm1_auto_point4_temp       65
write_val pwm1_auto_point4_temp_hyst  57
write_val pwm1_auto_point5_temp       70
write_val pwm1_auto_point5_temp_hyst  62
write_val pwm1_auto_point6_temp       75
write_val pwm1_auto_point6_temp_hyst  67
write_val pwm1_auto_point7_temp       80
write_val pwm1_auto_point7_temp_hyst  72
write_val pwm1_auto_point8_temp       85
write_val pwm1_auto_point8_temp_hyst  77
write_val pwm1_auto_point9_temp       90
write_val pwm1_auto_point9_temp_hyst  82
write_val pwm1_auto_point10_temp      127
write_val pwm1_auto_point10_temp_hyst 87

# ============================================================================
# GPU temperature thresholds (degrees C) — EDIT THESE VALUES
# ============================================================================

echo "Setting GPU temp thresholds..."
write_val pwm2_auto_point1_temp       50
write_val pwm2_auto_point1_temp_hyst  0
write_val pwm2_auto_point2_temp       55
write_val pwm2_auto_point2_temp_hyst  47
write_val pwm2_auto_point3_temp       60
write_val pwm2_auto_point3_temp_hyst  52
write_val pwm2_auto_point4_temp       65
write_val pwm2_auto_point4_temp_hyst  57
write_val pwm2_auto_point5_temp       70
write_val pwm2_auto_point5_temp_hyst  62
write_val pwm2_auto_point6_temp       75
write_val pwm2_auto_point6_temp_hyst  67
write_val pwm2_auto_point7_temp       80
write_val pwm2_auto_point7_temp_hyst  72
write_val pwm2_auto_point8_temp       85
write_val pwm2_auto_point8_temp_hyst  77
write_val pwm2_auto_point9_temp       90
write_val pwm2_auto_point9_temp_hyst  82
write_val pwm2_auto_point10_temp      127
write_val pwm2_auto_point10_temp_hyst 87

# ============================================================================
# IC temperature thresholds (degrees C) — EDIT THESE VALUES
# ============================================================================
# IC temperature often limits fan behavior. Set high values (127) to disable.

echo "Setting IC temp thresholds..."
write_val pwm3_auto_point1_temp       55
write_val pwm3_auto_point1_temp_hyst  0
write_val pwm3_auto_point2_temp       60
write_val pwm3_auto_point2_temp_hyst  52
write_val pwm3_auto_point3_temp       65
write_val pwm3_auto_point3_temp_hyst  57
write_val pwm3_auto_point4_temp       70
write_val pwm3_auto_point4_temp_hyst  62
write_val pwm3_auto_point5_temp       75
write_val pwm3_auto_point5_temp_hyst  67
write_val pwm3_auto_point6_temp       127
write_val pwm3_auto_point6_temp_hyst  72
write_val pwm3_auto_point7_temp       127
write_val pwm3_auto_point7_temp_hyst  127
write_val pwm3_auto_point8_temp       127
write_val pwm3_auto_point8_temp_hyst  127
write_val pwm3_auto_point9_temp       127
write_val pwm3_auto_point9_temp_hyst  127
write_val pwm3_auto_point10_temp      127
write_val pwm3_auto_point10_temp_hyst 127

# ============================================================================
# Acceleration / Deceleration (optional) — EDIT THESE VALUES
# ============================================================================
# Higher values = slower speed change. Range: 0-10 typical.

echo "Setting acceleration/deceleration..."
for i in 1 2 3 4 5 6 7 8 9 10; do
    write_val "pwm1_auto_point${i}_accel" 3
    write_val "pwm1_auto_point${i}_decel" 3
done

echo ""
echo "Fan curve written successfully."
echo ""

# Show the result
if [ -f /sys/kernel/debug/legion/fancurve ]; then
    echo "Current fan curve:"
    cat /sys/kernel/debug/legion/fancurve 2>/dev/null | head -20
fi
