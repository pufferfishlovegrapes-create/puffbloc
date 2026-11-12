#!/usr/bin/env bash
set -Eeuo pipefail

: "${VNC_PASSWORD:?Set VNC_PASSWORD before starting this container}"
if [ "${#VNC_PASSWORD}" -lt 8 ]; then
  echo "VNC_PASSWORD must be at least 8 characters." >&2
  exit 1
fi

mkdir -p /home/sober/.vnc
chown -R sober:sober /home/sober
printf '%s\n' "$VNC_PASSWORD" | su -s /bin/bash sober -c 'vncpasswd -f > /home/sober/.vnc/passwd'
chmod 600 /home/sober/.vnc/passwd
chown sober:sober /home/sober/.vnc/passwd

cat > /home/sober/.vnc/xstartup <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-run-session -- bash -lc '
  openbox-session &
  sleep 2
  exec flatpak run --device=all --socket=x11 --share=ipc org.vinegarhq.Sober
'
XSTARTUP
chmod 0755 /home/sober/.vnc/xstartup
chown sober:sober /home/sober/.vnc/xstartup

su -s /bin/bash sober -c "tigervncserver :1 -localhost yes -geometry ${RESOLUTION} -depth 24 -SecurityTypes VncAuth -PasswordFile /home/sober/.vnc/passwd"

# noVNC serves the browser client and proxies WebSocket traffic to TigerVNC.
exec websockify --web=/usr/share/novnc "${NOVNC_PORT}" 127.0.0.1:"${VNC_PORT}"
