#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

# ==========================================
# iMac 2017 Cirrus Audio-Treiber Setup
# ==========================================
echo "=== Installing iMac Audio Driver ==="

# 1. Benötigte Build-Tools temporär installieren
rpm-ostree install --target-arch x86_64 gcc make git patch kernel-devel

# 2. Treiber herunterladen und kompilieren
git clone https://github.com /tmp/snd_hda_macbookpro
cd /tmp/snd_hda_macbookpro
make

# 3. Kompilierten Treiber an die richtige Stelle kopieren
mkdir -p /usr/lib/modules/updates/
cp snd-hda-codec-cs8409.ko /usr/lib/modules/updates/

# 4. Autostart-Konfiguration für den Treiber anlegen
mkdir -p /etc/modules-load.d/
echo "snd-hda-codec-cs8409" > /etc/modules-load.d/snd_hda_macbookpro.conf

# 5. Kernel-Abhängigkeiten aktualisieren
depmod -a $(ls /usr/lib/modules/)

# 6. Aufräumen: Build-Tools wieder entfernen, um das Image schlank zu halten
rpm-ostree override remove gcc make git patch kernel-devel

echo "=== Audio Driver Installation Complete ==="
