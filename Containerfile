=========================================================================
# STAGE 1: Treiber in einer temporären Entwicklungsumgebung kompilieren
# =========================================================================
# HINWEIS: Wenn du GNOME nutzt, ändere "bazzite:stable" in "bazzite-gnome:stable"
FROM ghcr.io/ublue-os/bazzite:stable AS builder

# Notwendige Build-Tools und Kernel-Header installieren
RUN rpm-ostree install --target-arch x86_64 gcc make git patch kernel-devel && \
    ostree container commit

# Den Cirrus-Audiotreiber aus der Mac-Community klonen und bauen
RUN git clone https://github.com /tmp/snd_hda_macbookpro && \
    cd /tmp/snd_hda_macbookpro && \
    make

# =========================================================================
# STAGE 2: Das eigentliche Universal Blue Image bauen
# =========================================================================
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# HINWEIS: Wenn du GNOME nutzt, ändere auch hier "bazzite:stable" in "bazzite-gnome:stable"
FROM ghcr.io/ublue-os/bazzite:stable

# Das kompilierte Kernel-Modul (.ko) aus Stage 1 kopieren
COPY --from=builder /tmp/snd_hda_macbookpro/snd-hda-codec-cs8409.ko /usr/lib/modules/updates/

# Autostart für das Audiomodul einrichten
RUN mkdir -p /etc/modules-load.d/ && \
    echo "snd-hda-codec-cs8409" > /etc/modules-load.d/snd_hda_macbookpro.conf

# Kernel-Modul-Abhängigkeiten aktualisieren
RUN depmod -a $(ls /usr/lib/modules/)

# Standard-Modifikationen aus dem Template ausführen (build.sh)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# Image überprüfen
RUN bootc container lint
