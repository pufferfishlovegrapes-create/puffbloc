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
  cp .env.example .env
  echo "Created .env from .env.example."
  echo "Edit .env and set WEB_PASSWORD, then run: bash run.sh"
  exit 0
fi

if grep -q '^WEB_PASSWORD=replace-with-a-long-unique-password$' .env; then
  echo "Please replace the example WEB_PASSWORD in .env before starting." >&2
  exit 1
fi

docker compose config --quiet
docker compose up -d --build

echo
echo "Puffbloc has been started."
echo "Open http://localhost:8080 (or the public HTTPS URL configured by your host)."
echo "First startup installs Sober from Flathub; check logs if it takes a while:"
echo "  docker compose logs -f puffbloc"
