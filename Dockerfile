FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV HOME=/home/sober
ENV RESOLUTION=1280x720
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl dbus dbus-x11 flatpak \
    openbox xterm \
    tigervnc-standalone-server tigervnc-tools \
    novnc websockify \
    mesa-utils mesa-vulkan-drivers libgl1 libegl1 libgles2 libvulkan1 \
    x11-xserver-utils procps \
    && rm -rf /var/lib/apt/lists/*

# Install Sober from its official Flathub package.
RUN flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
    && flatpak install --system -y flathub org.vinegarhq.Sober 


RUN useradd --create-home --shell /bin/bash sober \
    && mkdir -p /home/sober/.vnc \
    && chown -R sober:sober /home/sober

COPY start.sh /usr/local/bin/start-sober
RUN chmod 0755 /usr/local/bin/start-sober

EXPOSE 6080

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD curl -fsS http://127.0.0.1:6080/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start-sober"]
