#!/usr/bin/env bash
set -Eeuo pipefail

: "${WEB_PASSWORD:?Set WEB_PASSWORD to a strong password before starting Puffbloc}"
if [ "${#WEB_PASSWORD}" -lt 12 ]; then
  echo "WEB_PASSWORD must be at least 12 characters." >&2
  exit 1
fi

WEB_USER="${WEB_USER:-puffbloc}"
PORT="${PORT:-8080}"
export WEB_USER WEB_PASSWORD PORT

# Flatpak needs the system D-Bus; Selkies session creates the display
# and audio session for XFCE.
mkdir -p /run/dbus
if [ ! -S /run/dbus/system_bus_socket ]; then
  dbus-daemon --system --fork --nopidfile
fi

install -d -o sober -g sober /home/sober/.config/autostart
cat > /home/sober/.config/autostart/puffbloc-sober.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Puffbloc Sober
Comment=Launch Sober when the remote desktop starts
Exec=/usr/local/bin/launch-sober
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
chown sober:sober /home/sober/.config/autostart/puffbloc-sober.desktop

echo "Starting Puffbloc on port ${PORT}..."
echo "Browser login user: ${WEB_USER}"

exec su -p -s /bin/bash sober -c '
  exec dbus-run-session -- /usr/local/bin/selkies session \
    --session=xfce \
    --public \
    --port="$PORT" \
    --enable-https=false \
    --basic-auth-user="$WEB_USER" \
    --basic-auth-password="$WEB_PASSWORD"
'
