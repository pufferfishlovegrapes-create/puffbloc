#!/usr/bin/env bash
set -Eeuo pipefail

: "${WEB_PASSWORD:?Set WEB_PASSWORD to a strong password before starting Puffbloc}"
if [ "${#WEB_PASSWORD}" -lt 12 ]; then
  echo "WEB_PASSWORD must be at least 12 characters." >&2
  exit 1
fi

WEB_USER="${WEB_USER:-puffbloc}"
PORT="${PORT:-8080}"

# Flatpak needs a system D-Bus. Selkies creates the user's session bus,
# virtual display and audio server when its session starts.
mkdir -p /run/dbus
if [ ! -S /run/dbus/system_bus_socket ]; then
  dbus-daemon --system --fork --nopidfile
fi

install -d -o sober -g sober /home/sober/.config/openbox
cat > /home/sober/.config/openbox/autostart <<'AUTOSTART'
#!/bin/sh
# Wait until Openbox and the virtual X display are ready, then launch Sober.
(sleep 5; flatpak run org.vinegarhq.Sober >> /home/sober/sober.log 2>&1) &
AUTOSTART
chown sober:sober /home/sober/.config/openbox/autostart
chmod 0755 /home/sober/.config/openbox/autostart

echo "Starting Puffbloc browser session on port ${PORT}..."
echo "Selkies login user: ${WEB_USER}"

exec su -s /bin/bash sober -c \
  "exec dbus-run-session -- /usr/local/bin/selkies session --session=openbox-session --public --port=${PORT} --enable-https=false --basic-auth-user='${WEB_USER}' --basic-auth-password='${WEB_PASSWORD}'"
