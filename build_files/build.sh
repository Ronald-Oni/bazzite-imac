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

# 1. Ziel-Kernel-Version des Bazzite-Images ermitteln (statt Host-Kernel des CI-Runners)
KERNEL_VER=$(ls /lib/modules | sort -V | tail -n 1)
echo "Ziel-Kernel: ${KERNEL_VER}"

# 2. Build-Pakete mit dnf installieren (rpm-ostree funktioniert nicht im Container-Build Context)
dnf install -y gcc make git patch kernel-devel-${KERNEL_VER} || dnf install -y gcc make git patch kernel-devel

# 3. Repository klonen
cd /tmp
git clone https://github.com/davidjo/snd_hda_macbookpro.git
cd snd_hda_macbookpro

# 4. Kompilieren mit explizitem Pfad zum Container-Kernel
make KDIR=/lib/modules/${KERNEL_VER}/build

# 5. Treiber in das Kernel-Verzeichnis des Images kopieren
MODULE_DIR="/usr/lib/modules/${KERNEL_VER}/updates"
mkdir -p "${MODULE_DIR}"
find . -name "snd-hda-codec-cs8409.ko" -exec cp {} "${MODULE_DIR}/" \;

# 6. Rechte vergeben und Modulabhängigkeiten für den Ziel-Kernel bauen
chmod 644 "${MODULE_DIR}"/*.ko
depmod -a "${KERNEL_VER}"

# 7. Autostart-Eintrag anlegen
mkdir -p /usr/lib/modules-load.d/
echo "snd-hda-codec-cs8409" > /usr/lib/modules-load.d/snd_hda_macbookpro.conf

# 8. Build-Tools entfernen (reduziert die Image-Größe)
dnf remove -y gcc make git patch kernel-devel
dnf clean all
rm -rf /tmp/snd_hda_macbookpro

echo "=== Audio Driver Installation Complete ==="