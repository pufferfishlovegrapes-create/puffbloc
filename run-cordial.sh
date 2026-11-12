#!/usr/bin/env bash
set -Eeuo pipefail

BASE_COMPOSE=(-f compose.cordial.yaml)

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or is not on PATH." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  password="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  cat > .env <<EOF
WEB_PASSWORD=$password
WEB_USER=ubuntu
WEB_PORT=8080
SCREEN_WIDTH=1280
SCREEN_HEIGHT=720
EOF
  echo "Created .env with a generated browser password:"
  echo "$password"
  echo "Keep this password private."
  echo
fi

if compgen -G "/dev/dri/renderD*" > /dev/null; then
  render_node="$(find /dev/dri -maxdepth 1 -type c -name 'renderD*' -print -quit)"
  export RENDER_GID
  RENDER_GID="$(stat -c '%g' "$render_node")"
  echo "GPU render node detected: $render_node (group $RENDER_GID)"
  BASE_COMPOSE+=(-f compose.cordial.gpu.yaml)
else
  echo "No /dev/dri render node detected. The session will start without GPU passthrough."
  echo "Roblox performance may be poor or Cordial may not start."
fi

docker compose "${BASE_COMPOSE[@]}" config --quiet
docker compose "${BASE_COMPOSE[@]}" up -d --build

echo
echo "Puffbloc Cordial has been started."
echo "Open forwarded port ${WEB_PORT:-8080} in your browser."
echo "Sign in with ${WEB_USER:-ubuntu} and the WEB_PASSWORD shown above (or stored in .env)."
echo "First run: create a Cordial profile, choose Download Roblox, then sign in."
echo "Logs: docker compose ${BASE_COMPOSE[*]} logs -f puffbloc-cordial"
