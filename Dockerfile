# Puffbloc: Sober + browser streaming via Selkies.
# Selkies AppImage provides the browser client, virtual display, audio and input.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG SELKIES_VERSION=2.2.1

ENV HOME=/home/sober
ENV USER=sober
ENV DISPLAY=:0
ENV PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl dbus dbus-x11 flatpak \
    openbox xterm xdg-utils \
    libgbm1 libegl1 libgl1 libgles2 libvulkan1 \
    libgl1-mesa-dri mesa-vulkan-drivers mesa-utils vulkan-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Sober from its official Flathub distribution.
RUN flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak install --system --noninteractive -y flathub org.vinegarhq.Sober

# Selkies is pinned to a release. Extract the AppImage so FUSE is not needed.
RUN curl -fL --retry 3 \
      "https://github.com/selkies-project/selkies/releases/download/${SELKIES_VERSION}/selkies-${SELKIES_VERSION}-x86_64.AppImage" \
      -o /tmp/selkies.AppImage \
    && chmod 0755 /tmp/selkies.AppImage \
    && cd /opt \
    && /tmp/selkies.AppImage --appimage-extract \
    && mv /opt/squashfs-root /opt/selkies \
    && ln -s /opt/selkies/AppRun /usr/local/bin/selkies \
    && rm -f /tmp/selkies.AppImage

RUN useradd --create-home --shell /bin/bash sober \
    && mkdir -p /home/sober/.config/openbox /home/sober/.var/app \
    && chown -R sober:sober /home/sober

COPY start.sh /usr/local/bin/start-puffbloc
RUN chmod 0755 /usr/local/bin/start-puffbloc

VOLUME ["/home/sober/.var/app"]
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/start-puffbloc"]
