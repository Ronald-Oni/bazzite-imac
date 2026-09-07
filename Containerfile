FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Nutzt immer das aktuellste, stabile Bazzite-Image ohne fehleranfällige Hash-IDs
FROM ghcr.io/ublue-os/bazzite:stable

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
RUN bootc container lint
