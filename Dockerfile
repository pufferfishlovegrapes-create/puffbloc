# Puffbloc: headless Ubuntu + Sober + GPU-capable TigerVNC + noVNC.
# Ubuntu 26.04 provides TigerVNC 1.15, whose Xvnc supports DRI3 render nodes.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    HOME=/home/ubuntu \
    XDG_RUNTIME_DIR=/tmp/runtime-ubuntu \
    SCREEN_RESOLUTION=1280x720 \
    DRI_RENDER_NODE=auto

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl flatpak bubblewrap xdg-dbus-proxy dbus \
       openbox tigervnc-standalone-server tigervnc-tools \
       novnc websockify x11-utils procps mesa-utils \
       fonts-dejavu-core \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash ubuntu \
    && mkdir -p /home/ubuntu/.local/share/flatpak \
                /home/ubuntu/.var/app \
                /home/ubuntu/.cache/puffbloc \
                /home/ubuntu/.vnc \
    && chown -R ubuntu:ubuntu /home/ubuntu

COPY entrypoint.sh /usr/local/bin/puffbloc-entrypoint
RUN chmod 0755 /usr/local/bin/puffbloc-entrypoint

# Persist the per-user Flatpak installation and Sober/Roblox data.
VOLUME ["/home/ubuntu/.local/share/flatpak", "/home/ubuntu/.var/app"]

EXPOSE 8080

USER ubuntu
WORKDIR /home/ubuntu
ENTRYPOINT ["/usr/local/bin/puffbloc-entrypoint"]
