#!/bin/bash
set -ouex pipefail

# ==========================================
# 1. Originaler Bazzite / uBlue Template Code
# ==========================================
cp -avf "/ctx/system_files"/. /
dnf5 install -y tmux
systemctl enable podman.socket

# ==========================================
# 2. iMac 2017 Cirrus Audio-Treiber Setup
# ==========================================
echo "=== Installing iMac Audio Driver ==="

# Ziel-Kernel im Bazzite-Container ermitteln
KERNEL_VER=$(ls /lib/modules | sort -V | tail -n 1)
echo "Ziel-Kernel: ${KERNEL_VER}"

# Build-Tools UND Download-Werkzeuge installieren (install.cirrus.driver.sh benötigt wget/tar/xz)
dnf5 install -y gcc make git patch wget tar xz bzip2 kernel-devel-${KERNEL_VER} || dnf5 install -y gcc make git patch wget tar xz bzip2 kernel-devel

# Repository klonen
cd /tmp
rm -rf snd_hda_macbookpro
git clone https://github.com/davidjo/snd_hda_macbookpro.git
cd snd_hda_macbookpro

# Ausführrechte setzen und das offizielle Build-/Installationsskript mit dem Ziel-Kernel ausführen
chmod +x install.cirrus.driver.sh
./install.cirrus.driver.sh -k "${KERNEL_VER}"

# Überprüfen, ob die Kernel-Modul-Datei tatsächlich erzeugt wurde
MODULE_FILE=$(find /usr/lib/modules/${KERNEL_VER} -name "snd-hda-codec-cs8409.ko*" | head -n 1)
if [ -z "${MODULE_FILE}" ]; then
    echo "ERROR: Kernel-Modul snd-hda-codec-cs8409.ko wurde nicht erstellt!"
    exit 1
fi
echo "Modul erfolgreich erstellt unter: ${MODULE_FILE}"

# Modulabhängigkeiten für den Ziel-Kernel aktualisieren
depmod -a "${KERNEL_VER}"

# Autostart-Eintrag für Bazzite anlegen
mkdir -p /usr/lib/modules-load.d/
echo "snd-hda-codec-cs8409" > /usr/lib/modules-load.d/snd_hda_macbookpro.conf

# Build-Tools entfernen (hält das Image schlank)
dnf5 remove -y gcc make git patch wget kernel-devel
dnf5 clean all
rm -rf /tmp/snd_hda_macbookpro

echo "=== Audio Driver Installation Complete ==="