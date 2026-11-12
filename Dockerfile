# Puffbloc: Sober streamed to a browser with Selkies.
# This is an experimental image; GPU support still depends on the host.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG SELKIES_VERSION=2.1.0

ENV HOME=/home/sober \
    USER=sober \
    PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl dbus dbus-x11 flatpak \
    xfce4 xfce4-goodies \
    libgbm1 libegl1 libgl1 libgles2 libvulkan1 \
    libgl1-mesa-dri mesa-vulkan-drivers mesa-utils vulkan-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Sober from Flathub.
RUN flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak install --system --noninteractive -y flathub org.vinegarhq.Sober

# Extract the official Selkies AppImage so the container does not need /dev/fuse.
RUN curl -fL --retry 3 \
      "https://github.com/selkies-project/selkies/releases/download/${SELKIES_VERSION}/selkies-${SELKIES_VERSION}-x86_64.AppImage" \
      -o /tmp/selkies.AppImage \
    && chmod 0755 /tmp/selkies.AppImage \
    && mkdir -p /opt/selkies \
    && cd /opt/selkies \
    && /tmp/selkies.AppImage --appimage-extract \
    && mv squashfs-root extracted \
    && ln -s /opt/selkies/extracted/AppRun /usr/local/bin/selkies \
    && rm -f /tmp/selkies.AppImage

RUN useradd --create-home --shell /bin/bash sober \
    && mkdir -p /home/sober/.config/autostart /home/sober/.var/app \
    && chown -R sober:sober /home/sober

COPY start.sh /usr/local/bin/start-puffbloc
COPY launch-sober.sh /usr/local/bin/launch-sober
RUN chmod 0755 /usr/local/bin/start-puffbloc /usr/local/bin/launch-sober

# Sober's Flatpak data and downloaded Roblox files survive container restarts.
VOLUME ["/home/sober/.var/app"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD-SHELL curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start-puffbloc"]
