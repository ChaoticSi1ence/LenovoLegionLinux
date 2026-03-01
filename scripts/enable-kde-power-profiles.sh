#!/bin/bash
# =============================================================================
# Enable KDE Power Profile Control for Legion Laptop
# =============================================================================
#
# Removes the power-profiles-daemon override that blocks platform_profile,
# allowing KDE's power slider to control firmware thermal modes directly:
#
#   KDE Power Save   → Quiet (firmware mode 1)
#   KDE Balanced     → Balanced (firmware mode 2)
#   KDE Performance  → Performance (firmware mode 3)
#
# Usage: sudo bash scripts/enable-kde-power-profiles.sh
#        sudo bash scripts/enable-kde-power-profiles.sh --revert
# =============================================================================

set -euo pipefail

OVERRIDE_DIR="/etc/systemd/system/power-profiles-daemon.service.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"
BACKUP_FILE="${OVERRIDE_DIR}/override.conf.bak"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UDEV_RULE_SRC="${SCRIPT_DIR}/../deploy/99-legion-ppd-restart.rules"
UDEV_RULE_DST="/etc/udev/rules.d/99-legion-ppd-restart.rules"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must run as root (sudo)." >&2
    exit 1
fi

# --- Revert mode ---
if [ "${1:-}" = "--revert" ]; then
    echo "=== Reverting: Re-blocking platform_profile ==="

    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$OVERRIDE_FILE"
        echo "Restored override from backup"
    else
        mkdir -p "$OVERRIDE_DIR"
        cat > "$OVERRIDE_FILE" <<'EOF'
# Block PPD from controlling Lenovo WMI firmware platform profile.
# PPD will only manage CPU governor (intel_pstate EPP).
# Use Fn+Q or sysfs to change firmware thermal modes.

[Service]
ExecStart=
ExecStart=/usr/lib/power-profiles-daemon --block-driver=platform_profile
EOF
        echo "Recreated override (no backup found)"
    fi

    # Remove udev rule (no longer needed when PPD is blocked)
    if [ -f "$UDEV_RULE_DST" ]; then
        rm -f "$UDEV_RULE_DST"
        udevadm control --reload-rules 2>/dev/null || true
        echo "Removed udev rule $UDEV_RULE_DST"
    fi

    systemctl daemon-reload
    systemctl restart power-profiles-daemon
    echo "PPD restarted with platform_profile BLOCKED"
    echo ""
    echo "KDE slider now only controls CPU governor, not firmware modes."
    exit 0
fi

# --- Enable mode ---
echo "=== Enabling KDE power profile → firmware mode control ==="
echo ""

# Check PPD is installed
if ! command -v powerprofilesctl &>/dev/null; then
    echo "ERROR: power-profiles-daemon not installed." >&2
    exit 1
fi

# Check current state
if [ ! -f "$OVERRIDE_FILE" ]; then
    echo "No override file found at $OVERRIDE_FILE"
    echo "PPD may already be using platform_profile."
    echo ""
    echo "Current state:"
    powerprofilesctl list 2>/dev/null || true
    exit 0
fi

echo "Found override: $OVERRIDE_FILE"
echo "Contents:"
sed 's/^/  /' "$OVERRIDE_FILE"
echo ""

# Check that legion_laptop owns the platform profile
if [ -f /sys/class/platform-profile/platform-profile-0/name ]; then
    OWNER=$(cat /sys/class/platform-profile/platform-profile-0/name)
    echo "platform_profile owner: $OWNER"
else
    echo "WARNING: No platform_profile device found."
    echo "Is legion_laptop loaded with enable_platformprofile=true?"
    exit 1
fi

CHOICES=$(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null || echo "unknown")
CURRENT=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "unknown")
echo "Available profiles: $CHOICES"
echo "Current profile: $CURRENT"
echo ""

# Backup and remove
echo "Backing up override to ${BACKUP_FILE}..."
cp "$OVERRIDE_FILE" "$BACKUP_FILE"

echo "Removing override..."
rm "$OVERRIDE_FILE"

# Remove empty dir if nothing else is in it
rmdir "$OVERRIDE_DIR" 2>/dev/null || true

echo "Reloading systemd and restarting PPD..."
systemctl daemon-reload
systemctl restart power-profiles-daemon

# Install udev rule to handle boot race condition
if [ -f "$UDEV_RULE_SRC" ]; then
    echo ""
    echo "Installing udev rule for PPD restart on module load..."
    cp -f "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
    udevadm control --reload-rules 2>/dev/null || true
    echo "  Installed $UDEV_RULE_DST"
elif [ ! -f "$UDEV_RULE_DST" ]; then
    echo ""
    echo "WARNING: udev rule source not found at $UDEV_RULE_SRC"
    echo "PPD may not auto-detect platform_profile after reboot."
    echo "Run build-legion-module.sh to install the udev rule."
fi

# Wait for PPD to settle
sleep 1

# Verify
echo ""
echo "=== Verification ==="
echo ""
echo "PPD status:"
powerprofilesctl list 2>/dev/null || echo "  (could not query)"
echo ""

# Check if PPD now uses platform_profile
PPD_DRIVER=$(busctl introspect org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles 2>/dev/null | grep -i platform || echo "")
if [ -n "$PPD_DRIVER" ]; then
    echo "PPD is now using platform_profile driver"
else
    echo "Checking D-Bus profiles..."
    busctl call org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles org.freedesktop.DBus.Properties GetAll s org.freedesktop.UPower.PowerProfiles 2>/dev/null | head -5 || true
fi

echo ""
echo "=== Done ==="
echo ""
echo "KDE power slider now controls firmware thermal modes:"
echo "  Power Save  → Quiet  (low power, fans minimal)"
echo "  Balanced    → Balanced (moderate power)"
echo "  Performance → Performance (full power, fans aggressive)"
echo ""
echo "To revert: sudo bash $0 --revert"
