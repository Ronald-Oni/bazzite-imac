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

# Ziel-Kernel-Version im Bazzite-Container ermitteln
KERNEL_VER=$(ls /lib/modules | sort -V | tail -n 1)
echo "Ziel-Kernel: ${KERNEL_VER}"

# Build-Tools und passende Kernel-Header über dnf5 installieren
dnf5 install -y gcc make git patch kernel-devel-${KERNEL_VER} || dnf5 install -y gcc make git patch kernel-devel

# Symlink prüfen und ggf. setzen, falls die Header unter /usr/src/kernels liegen
KERNEL_DIR="/lib/modules/${KERNEL_VER}/build"
if [ ! -d "${KERNEL_DIR}" ]; then
    ALT_DIR=$(ls -d /usr/src/kernels/${KERNEL_VER}* 2>/dev/null | head -n 1)
    if [ -n "${ALT_DIR}" ]; then
        echo "Erstelle Symlink: ${KERNEL_DIR} -> ${ALT_DIR}"
        ln -snf "${ALT_DIR}" "${KERNEL_DIR}"
    fi
fi

# Driver-Repository klonen
cd /tmp
rm -rf snd_hda_macbookpro
git clone https://github.com/davidjo/snd_hda_macbookpro.git
cd snd_hda_macbookpro

# Kompilieren mit den exakten Makefile-Variablen des Repositories
echo "Kompiliere Treiber für Kernel ${KERNEL_VER}..."
make KERNELRELEASE="${KERNEL_VER}" KERNEL_DIR="${KERNEL_DIR}"

# Kompiliertes Kernel-Modul (.ko) in das Updates-Verzeichnis kopieren
MODULE_DIR="/usr/lib/modules/${KERNEL_VER}/updates"
mkdir -p "${MODULE_DIR}"
find . -name "*.ko" -exec cp {} "${MODULE_DIR}/" \;

# Rechte setzen und Modulabhängigkeiten für den Bazzite-Kernel aktualisieren
chmod 644 "${MODULE_DIR}"/*.ko
depmod -a "${KERNEL_VER}"

# Autostart-Eintrag im schreibgeschützten Systempfad hinterlegen
mkdir -p /usr/lib/modules-load.d/
echo "snd-hda-codec-cs8409" > /usr/lib/modules-load.d/snd_hda_macbookpro.conf

# Temporäre Dateien und Build-Tools entfernen (hält das Image schlank)
dnf5 remove -y gcc make git patch kernel-devel
dnf5 clean all
rm -rf /tmp/snd_hda_macbookpro

echo "=== Audio Driver Installation Complete ==="