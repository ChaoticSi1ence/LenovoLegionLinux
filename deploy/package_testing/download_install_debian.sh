#!/bin/bash
set -e
sudo apt install -y curl

DEBVER="0.0.20+ds-1"
DEBMIRROR="https://ftp.de.debian.org/debian/pool/contrib/l/lenovolegionlinux"

sudo curl "${DEBMIRROR}/lenovolegionlinux-dkms_${DEBVER}_amd64.deb" -o "/tmp/lenovolegionlinux-dkms_${DEBVER}_amd64.deb"
sudo curl "${DEBMIRROR}/python3-legion-linux_${DEBVER}_all.deb" -o "/tmp/python3-legion-linux_${DEBVER}_all.deb"
sudo curl "${DEBMIRROR}/legiond_${DEBVER}_amd64.deb" -o "/tmp/legiond_${DEBVER}_amd64.deb"

sudo apt install -y "/tmp/lenovolegionlinux-dkms_${DEBVER}_amd64.deb"
sudo apt install -y "/tmp/python3-legion-linux_${DEBVER}_all.deb"
sudo apt install -y "/tmp/legiond_${DEBVER}_amd64.deb"
