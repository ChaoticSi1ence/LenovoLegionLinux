#!/bin/bash
set -ex
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPODIR="${DIR}/.."

cd ${REPODIR}/python/legion_linux

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root to install"
	exit 1
fi

rm -f /usr/share/applications/legion_gui.desktop
rm -f /usr/share/icons/legion_logo.png
rm -f /usr/share/polkit-1/actions/legion_cli.policy
rm -f /usr/share/polkit-1/actions/legion_gui.policy
sudo pip3 uninstall legion_linux
