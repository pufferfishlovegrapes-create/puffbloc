# Puffbloc — headless Sober in your browser

Puffbloc runs **Sober** (the unofficial Linux Roblox client) in a minimal, headless Ubuntu container.

- **No full desktop environment:** no XFCE, KDE, GNOME or Selkies.
- **Virtual display:** TigerVNC Xvnc creates the X11 display.
- **Browser access:** noVNC + Websockify.
- **Minimal window manager:** Openbox only, so Sober has a window to run in.
- **GPU support:** TigerVNC 1.15 supports DRI3 render-node acceleration with compatible graphics drivers.
- **Persistence:** Flatpak and Sober/Roblox data are kept in named Docker volumes.

Roblox runs inside Sober in the Linux container. The browser is only the remote display and input device; this is not a Roblox web client.

## Quick start

You need a Linux Docker host with Docker Compose v2.

1. Clone this repository onto the Docker host.
2. Run:

   ```bash
   bash run.sh
   ```

3. On first run, the helper creates `.env` and prints a generated noVNC password. Save it.
4. Open the host's forwarded **port 8080** in your browser.
5. When noVNC asks, enter the **first 8 characters** of `WEB_PASSWORD`.

TigerVNC's classic VNC password authentication uses only the first 8 characters. Do not reuse an important account password. For a public deployment, put the service behind your provider's HTTPS proxy and access controls; do not expose the raw VNC port (5901).

The first startup installs Sober from Flathub and can take several minutes. Sober may show its first-run Roblox setup; complete that setup in the browser.

## What runs inside the container

1. Ubuntu starts.
2. TigerVNC Xvnc creates display `:1`, optionally using a GPU render node.
3. Openbox starts as a minimal window manager.
4. Websockify serves noVNC on port 8080 and forwards WebSocket traffic to the local VNC server.
5. Flatpak installs Sober from the official Flathub remote if needed.
6. Sober launches automatically.

Only port 8080 is published. The VNC server listens on localhost inside the container.

## GPU acceleration

Sober requires an x86-64/AMD64 CPU with SSE4.1 and graphics capable of OpenGL ES 3.0 at minimum. SSE4.2 and Vulkan 1.1 are recommended. ARM is not supported. See the [official Sober requirements](https://vinegarhq.org/Sober/Installation.html).

TigerVNC 1.15's Xvnc supports GPU acceleration through DRI3 and a DRM render node on compatible open-source graphics drivers and newer NVIDIA drivers. The Ubuntu 26.04 base supplies TigerVNC 1.15.

For Intel or AMD graphics, the Docker host must expose `/dev/dri`. Check on the host:

```bash
ls -l /dev/dri/
stat -c '%g' /dev/dri/renderD128
```

Then start with the GPU override, replacing `109` with the render-node group ID from your host:

```bash
RENDER_GID=109 docker compose -f compose.yaml -f compose.gpu.yaml up -d --build
```

If your render node is not `/dev/dri/renderD128`, set `DRI_RENDER_NODE` to the actual device path and adjust the device mapping in `compose.gpu.yaml`.

A Dockerfile cannot create a GPU. If the provider does not expose a compatible GPU, Xvnc may fall back to software rendering, and Sober may refuse to start or perform poorly. GitHub Codespaces is useful for building and testing the browser stream, but do not assume it exposes a gaming GPU.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `WEB_PASSWORD` | Generated on first run | noVNC/VNC password; first 8 characters are used |
| `WEB_PORT` | `8080` | Host-side browser port |
| `SCREEN_RESOLUTION` | `1280x720` | Virtual display resolution |
| `DRI_RENDER_NODE` | `auto` | TigerVNC render node selection |

## Logs and diagnostics

```bash
docker compose logs -f puffbloc
docker compose exec puffbloc cat /home/ubuntu/.cache/puffbloc/xvnc.log
docker compose exec puffbloc cat /home/ubuntu/.cache/puffbloc/graphics.log
docker compose exec puffbloc cat /home/ubuntu/.cache/puffbloc/sober.log
```

The graphics log contains the renderer information reported by `glxinfo -B`. Check that it identifies the expected GPU rather than a software renderer.

## Persistence

- `puffbloc-flatpak`: Sober and Flatpak runtime installation.
- `puffbloc-data`: Sober settings and downloaded Roblox data.

Stop the container with:

```bash
docker compose down
```

This keeps the volumes. To delete the saved Sober installation and data too:

```bash
docker compose down -v
```

## Important limitations

- This is an experimental container setup, not yet validated end-to-end on every hosting provider.
- A successful Docker build does not prove that the host exposes a GPU or permits Flatpak's sandbox.
- Sober is an unofficial, experimental project and is not supported by Roblox.
- The browser viewer shows the virtual display; Sober must still complete its initial Roblox setup and the user must sign in normally.

## Upstream projects

- [Sober](https://sober.vinegarhq.org/)
- [Sober installation requirements](https://vinegarhq.org/Sober/Installation.html)
- [noVNC](https://github.com/novnc/noVNC)
- [TigerVNC](https://tigervnc.org/)
