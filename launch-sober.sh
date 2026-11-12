#!/usr/bin/env bash
set -Eeuo pipefail

# Give XFCE time to finish starting before opening Sober.
sleep 8
echo "Launching Sober..."
exec flatpak run --device=all org.vinegarhq.Sober >> /home/sober/sober.log 2>&1
