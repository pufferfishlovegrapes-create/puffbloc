# Puffbloc — Cordial browser session (experimental)

This is a separate experimental path. It does not replace the existing Sober setup.

It uses:
- Cordial's official Flatpak package.
- Selkies Base for a headless Wayland display and browser streaming.
- No LXQt, KDE, XFCE, or VNC server.
- Optional Intel/AMD GPU passthrough through `/dev/dri`.

## Start

On a Linux Docker host with Docker Compose v2:

```bash
bash run-cordial.sh
```

The helper detects a host render node and adds the GPU override automatically. If there is no `/dev/dri/renderD*`, it starts without GPU passthrough; that is useful for checking the web stream, but is not a valid test of gaming performance.

Open the forwarded port 8080. The Selkies page uses the username and password printed by the helper (the password is also stored in `.env`).

## First run

Cordial's first-run setup is interactive:
1. Create a Cordial profile.
2. Press **Download Roblox**.
3. Wait for the official Android build to download and pass Cordial's signature check.
4. Sign in normally.

Cordial does not ship Roblox's client. The download is initiated from Cordial's first-run screen and is verified before use.

The profile, sign-in state, and downloaded Roblox data are kept in the `cordial-data` Docker volume.

## Automatic game launch after setup

Cordial supports launching a saved profile with:

```bash
flatpak run --user io.github.luohoa97.Cordial --profile PROFILE_ID --play
```

To use that mode in this container, set `CORDIAL_PROFILE` in `.env` to the profile ID after creating it. Optionally set `CORDIAL_PLACE_ID` to a specific experience's place ID. Leave `CORDIAL_PROFILE` empty to open the Cordial launcher.

## Configuration

- `WEB_PASSWORD`: browser login and Linux session password.
- `WEB_USER`: browser login username (default `ubuntu`).
- `WEB_PORT`: published port (default `8080`).
- `SCREEN_WIDTH` / `SCREEN_HEIGHT`: streamed resolution.
- `CORDIAL_PROFILE`: optional saved profile ID for automatic game launch.
- `CORDIAL_PLACE_ID`: optional place ID to launch directly.
- `SELKIES_VERSION`: Selkies image tag (default `latest`).

## GPU requirements

For Intel/AMD, the Docker host must expose a DRM render node such as `/dev/dri/renderD128`. The helper passes `/dev/dri` into the container and adds the render-node group. A Dockerfile cannot create or emulate a physical iGPU.

## Important limitations

- This is experimental and has not yet been validated end-to-end.
- Cordial's primary display backend is Wayland. This setup uses Selkies' headless Wayland backend.
- Codespaces can test the image and browser stream, but usually does not provide a gaming iGPU. A successful Codespaces test does not prove GPU gameplay will work on the final host.
- The first Cordial profile creation, Roblox download, and sign-in are interactive. Subsequent startup can launch the saved profile automatically.
- Cordial is an unofficial Roblox client. Roblox does not officially support it, so use it with awareness of account and compatibility risks.

## Logs

```bash
docker compose -f compose.cordial.yaml logs -f puffbloc-cordial
docker exec puffbloc-cordial selkies gpu-probe
```

## Stop

```bash
docker compose -f compose.cordial.yaml down
```

The data volume is preserved. To remove it too, add `-v`.
