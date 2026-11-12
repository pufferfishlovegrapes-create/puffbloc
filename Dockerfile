# Puffbloc: Sober (Roblox) launched automatically in a browser-streamed desktop.
# Selkies provides the desktop, audio, GPU plumbing and browser streaming.
# Sober itself is installed from the official Flathub remote on first startup.
FROM ghcr.io/selkies-project/selkies/desktop:latest-ubuntu26.04

USER 0

ARG DEBIAN_FRONTEND=noninteractive

# Flatpak is required because Sober is officially distributed as a Flatpak.
# bubblewrap and xdg-dbus-proxy are Flatpak's sandbox helpers.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       flatpak bubblewrap xdg-dbus-proxy dbus-x11 ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY launch-sober.sh /usr/local/bin/puffbloc-launch-sober
COPY puffbloc-sober.desktop /usr/share/applications/puffbloc-sober.desktop

RUN chmod 0755 /usr/local/bin/puffbloc-launch-sober \
    && mkdir -p /home/ubuntu/.local/share/flatpak \
                /home/ubuntu/.var/app \
                /home/ubuntu/.cache/puffbloc \
    && chown -R 1000:1000 /home/ubuntu/.local/share/flatpak \
                          /home/ubuntu/.var/app \
                          /home/ubuntu/.cache/puffbloc \
    && cat >> /etc/xdg/openbox/autostart <<'AUTOSTART'

# Puffbloc: install Sober from Flathub on first boot, then launch it.
# Set PUFFBLOC_AUTO_START=0 to open the desktop without auto-launching Sober.
if [ "${PUFFBLOC_AUTO_START:-1}" = "1" ]; then
    /usr/local/bin/puffbloc-launch-sober &
fi
AUTOSTART

# Keep Flatpak's per-user installation and Sober's app data across restarts.
VOLUME ["/home/ubuntu/.local/share/flatpak", "/home/ubuntu/.var/app"]

EXPOSE 8080

# Keep the upstream Selkies entrypoint and its s6 service supervision.
USER 1000
