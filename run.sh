#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or is not on PATH." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required. Install or enable the Docker Compose plugin." >&2
  exit 1
fi

if [ ! -f .env ]; then
  generated_password="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
  cat > .env <<EOF
WEB_PASSWORD=${generated_password}
WEB_PORT=8080
SCREEN_RESOLUTION=1280x720
EOF
  echo "Created .env and generated a noVNC password:"
  echo "${generated_password}"
  echo "Save it. TigerVNC VNC authentication uses the first 8 characters."
  echo
fi

if grep -q '^WEB_PASSWORD=replace-with-a-long-unique-password$' .env; then
  echo "Please replace the example WEB_PASSWORD in .env before starting." >&2
  exit 1
fi

docker compose config --quiet
docker compose up -d --build

echo
echo "Puffbloc has been started."
echo "Open the forwarded port 8080 in your browser."
echo "Enter the first 8 characters of WEB_PASSWORD when noVNC asks."
echo "First startup installs Sober from Flathub; follow logs with:"
echo "  docker compose logs -f puffbloc"
