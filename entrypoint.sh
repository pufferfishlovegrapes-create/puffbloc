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

printf '%s\n' "${WEB_PASSWORD:0:8}" | tigervncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

echo "[Puffbloc] Starting TigerVNC display on $DISPLAY..."
XVNC_ARGS=("$DISPLAY" -geometry "$SCREEN_RESOLUTION" -depth 24 -rfbport 5901 -localhost -SecurityTypes VncAuth -rfbauth "$HOME/.vnc/passwd" -noreset -AlwaysShared)
if [[ -n "${DRI_RENDER_NODE:-}" ]]; then
  if [[ -e "$DRI_RENDER_NODE" ]]; then
    XVNC_ARGS+=( -rendernode "$DRI_RENDER_NODE" )
  else
    echo "ERROR: DRI_RENDER_NODE '$DRI_RENDER_NODE' does not exist. Check GPU passthrough."
    exit 1
  fi
fi
Xtigervnc "${XVNC_ARGS[@]}" >"$LOG_DIR/xvnc.log" 2>&1 &
XVNC_PID=$!

cleanup() {
  kill "${SOBER_PID:-}" "${WEBSOCKIFY_PID:-}" "${OPENBOX_PID:-}" "$XVNC_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[Puffbloc] Waiting for the virtual display..."
for _ in $(seq 1 60); do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then break; fi
  if ! kill -0 "$XVNC_PID" 2>/dev/null; then
    echo "ERROR: Xtigervnc exited. Its log follows:"
    cat "$LOG_DIR/xvnc.log"
    exit 1
  fi
  sleep 1
done
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  echo "ERROR: Xtigervnc did not become ready. Its log: $LOG_DIR/xvnc.log"
  cat "$LOG_DIR/xvnc.log"
  exit 1
fi

openbox --sm-disable >"$LOG_DIR/openbox.log" 2>&1 &
OPENBOX_PID=$!
websockify --web=/usr/share/novnc 8080 127.0.0.1:5901 >"$LOG_DIR/websockify.log" 2>&1 &
WEBSOCKIFY_PID=$!

glxinfo -B >"$LOG_DIR/graphics.log" 2>&1 || true

echo "[Puffbloc] Adding Flathub and installing Sober if needed..."
if ! flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
  flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL"
fi
if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  flatpak install --user --noninteractive --assumeyes flathub "$APP_ID"
fi

echo "[Puffbloc] Launching Sober..."
dbus-run-session -- flatpak run --user "$APP_ID" >"$LOG_DIR/sober.log" 2>&1 &
SOBER_PID=$!
echo "[Puffbloc] noVNC is starting on port 8080. Open the forwarded port in Codespaces."
echo "[Puffbloc] VNC password: first 8 characters of WEB_PASSWORD."
# Keep the web port alive even if Sober exits. Only stop the container if
# the display, window manager, or noVNC web server itself stops.
if wait -n "$XVNC_PID" "$OPENBOX_PID" "$WEBSOCKIFY_PID"; then
  echo "[Puffbloc] A core display/web process exited; container will restart."
else
  echo "[Puffbloc] A core display/web process failed; container will restart."
fi
