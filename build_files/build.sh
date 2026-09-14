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

# Build-Tools und Download-Werkzeuge installieren
dnf5 install -y gcc make git patch wget tar xz bzip2 kernel-devel-${KERNEL_VER} || dnf5 install -y gcc make git patch wget tar xz bzip2 kernel-devel

# Repository klonen
cd /tmp
rm -rf snd_hda_macbookpro
git clone https://github.com/davidjo/snd_hda_macbookpro.git
cd snd_hda_macbookpro

# FIX: Verhindert, dass das Makefile stumm depmod auf dem Host-Kernel aufruft
sed -i 's/depmod -a/true/g' Makefile

# Installer ausführen
chmod +x install.cirrus.driver.sh
./install.cirrus.driver.sh -k "${KERNEL_VER}"

# Modulabhängigkeiten explizit für den Bazzite-Kernel aktualisieren
depmod -a "${KERNEL_VER}"

# Überprüfen, ob das Modul am Zielort liegt
MODULE_FILE=$(find /usr/lib/modules/${KERNEL_VER} -name "snd-hda-codec-cs8409.ko*" | head -n 1)
if [ -z "${MODULE_FILE}" ]; then
    echo "ERROR: Kernel-Modul snd-hda-codec-cs8409.ko wurde nicht gefunden!"
    exit 1
fi
echo "Modul erfolgreich verifiziert: ${MODULE_FILE}"

# Autostart-Eintrag für Bazzite anlegen
mkdir -p /usr/lib/modules-load.d/
echo "snd-hda-codec-cs8409" > /usr/lib/modules-load.d/snd_hda_macbookpro.conf

# Build-Tools entfernen (hält das Image schlank)
dnf5 remove -y gcc make git patch wget kernel-devel
dnf5 clean all
rm -rf /tmp/snd_hda_macbookpro

echo "=== Audio Driver Installation Complete ==="

# ==========================================
# 3. Universeller WLAN Hardware-Fix (iMac 2017, 2019 & MacBooks)
# ==========================================
echo "=== Installing Universal Apple Wi-Fi Firmware ==="

cd /tmp

# Benötigte Werkzeuge zum Herunterladen und Entpacken installieren
dnf5 install -y curl binutils tar xz zstd

# FIX: Wir umgehen das erschöpfte Git-LFS-Traffic-Limit komplett!
# Statt das Repository zu klonen, laden wir direkt das fertige Release-Paket herunter.
curl -L -o apple-firmware.deb "https://github.com/AdityaGarg8/Apple-Firmware/releases/download/debian/apple-firmware_14.7.6-1_all.deb"

# Das Debian-Paket entpacken
ar x apple-firmware.deb
tar -xf data.tar.*

# Firmware-Dateien an den richtigen Ort im System kopieren
mkdir -p /usr/lib/firmware/brcm

if [ -d "usr/lib/firmware/brcm" ]; then
    cp -r usr/lib/firmware/brcm/* /usr/lib/firmware/brcm/
elif [ -d "lib/firmware/brcm" ]; then
    cp -r lib/firmware/brcm/* /usr/lib/firmware/brcm/
fi

# Inkompatiblen 'wl' Treiber sperren & Standard 'brcmfmac' laden
mkdir -p /usr/lib/modprobe.d/
echo "blacklist wl" > /usr/lib/modprobe.d/broadcom-wl-blacklist.conf

mkdir -p /usr/lib/modules-load.d/
echo "brcmfmac" > /usr/lib/modules-load.d/broadcom-wifi.conf

# Aufräumen (hält das fertige Image schlank)
cd /
rm -rf /tmp/apple-firmware.deb /tmp/control.tar.* /tmp/data.tar.* /tmp/debian-binary /tmp/usr /tmp/lib

# Bluetooth ERTM-Fix
mkdir -p /usr/lib/modprobe.d/
echo "options bluetooth disable_ertm=1" > /usr/lib/modprobe.d/bluetooth-ertm.conf

# ==========================================
# 4. AMD Radeon Overclocking & LACT GPU-Tool
# ==========================================
# Kernel-Argument für Overclocking/Undervolting fest im Image verankern
mkdir -p /usr/lib/bootc/kargs.d
cat <<EOF > /usr/lib/bootc/kargs.d/10-amdgpu.toml
kargs = ["amdgpu.ppfeaturemask=0xffffffff"]
EOF

# LACT über das offizielle COPR Repository (ilyaz/LACT) installieren
dnf5 copr enable -y ilyaz/LACT
dnf5 install -y lact
systemctl enable lactd
dnf5 copr disable -y ilyaz/LACT