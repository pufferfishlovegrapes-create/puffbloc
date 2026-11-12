#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="org.vinegarhq.Sober"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
LOG_DIR="$HOME/.cache/puffbloc"
mkdir -p "$LOG_DIR" "$HOME/.vnc" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

if [[ -z "${WEB_PASSWORD:-}" ]]; then
  echo "ERROR: WEB_PASSWORD is required. Set it in .env."
  exit 1
fi

# Classic VNC authentication uses only the first 8 password characters.
printf '%s\n' "${WEB_PASSWORD:0:8}" | tigervncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

echo "[Puffbloc] Starting headless Xvnc display on $DISPLAY..."
Xvnc "$DISPLAY" \
  -geometry "$SCREEN_RESOLUTION" \
  -depth 24 \
  -rfbport 5901 \
  -localhost \
  -SecurityTypes VncAuth \
  -rfbauth "$HOME/.vnc/passwd" \
  -rendernode "$DRI_RENDER_NODE" \
  -noreset \
  -AlwaysShared \
  >"$LOG_DIR/xvnc.log" 2>&1 &
XVNC_PID=$!

cleanup() {
  kill "${SOBER_PID:-}" "${WEBSOCKIFY_PID:-}" "${OPENBOX_PID:-}" "$XVNC_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[Puffbloc] Waiting for the virtual display..."
for _ in $(seq 1 60); do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$XVNC_PID" 2>/dev/null; then
    echo "ERROR: Xvnc exited. See $LOG_DIR/xvnc.log"
    cat "$LOG_DIR/xvnc.log"
    exit 1
  fi
  sleep 1
done
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  echo "ERROR: Xvnc did not become ready. See $LOG_DIR/xvnc.log"
  exit 1
fi

echo "[Puffbloc] Starting minimal Openbox window manager..."
openbox --sm-disable >"$LOG_DIR/openbox.log" 2>&1 &
OPENBOX_PID=$!

echo "[Puffbloc] Starting noVNC web gateway on port 8080..."
websockify --web=/usr/share/novnc 8080 127.0.0.1:5901 >"$LOG_DIR/websockify.log" 2>&1 &
WEBSOCKIFY_PID=$!

echo "[Puffbloc] Checking GPU/display renderer..."
glxinfo -B >"$LOG_DIR/graphics.log" 2>&1 || true

echo "[Puffbloc] Preparing Sober from the official Flathub remote..."
if ! flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
  flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL"
fi

if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  echo "[Puffbloc] First startup: installing Sober. This may take several minutes..."
  flatpak install --user --noninteractive --assumeyes flathub "$APP_ID"
fi

echo "[Puffbloc] Launching Sober on the headless display..."
dbus-run-session -- flatpak run --user "$APP_ID" >"$LOG_DIR/sober.log" 2>&1 &
SOBER_PID=$!

echo
echo "[Puffbloc] Ready. Open the forwarded port 8080 in your browser."
echo "[Puffbloc] noVNC password: the first 8 characters of WEB_PASSWORD."
echo "[Puffbloc] Sober and Roblox data are persisted in Docker volumes."
echo

wait -n "$XVNC_PID" "$OPENBOX_PID" "$WEBSOCKIFY_PID" "$SOBER_PID"
echo "[Puffbloc] A core process exited; stopping the container for restart."
