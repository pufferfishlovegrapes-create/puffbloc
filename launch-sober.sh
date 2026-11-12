#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="org.vinegarhq.Sober"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/puffbloc"
LOG_FILE="$LOG_DIR/sober-startup.log"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1

echo
echo "===== Puffbloc Sober launcher: $(date -Is) ====="

if ! command -v flatpak >/dev/null 2>&1; then
  echo "ERROR: Flatpak is missing from this image."
  exit 1
fi

# Avoid opening a second Sober window if the desktop launcher is clicked twice.
if pgrep -u "$(id -u)" -f "flatpak run.*$APP_ID" >/dev/null 2>&1; then
  echo "Sober already appears to be running."
  exit 0
fi

# Use a per-user Flatpak installation so no root daemon or system-wide
# installation is needed. The Compose volume preserves this installation.
if ! flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
  echo "Adding the official Flathub remote..."
  flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL"
fi

if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
  echo "First launch: installing Sober from Flathub. This can take a while..."
  flatpak install --user --noninteractive --assumeyes flathub "$APP_ID"
fi

echo "Starting Sober..."
exec flatpak run --user --device=all "$APP_ID"
