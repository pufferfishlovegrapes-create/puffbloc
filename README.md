# Puffbloc — Roblox Sober in your browser

Puffbloc starts **Sober** (the unofficial Linux Roblox client) inside an official **Selkies** browser-streamed Linux desktop.

- Selkies provides the desktop, audio, browser streaming and GPU plumbing.
- Sober is installed automatically from the official Flathub remote on first desktop startup.
- Sober's Flatpak installation and Roblox data are stored in persistent volumes.
- The browser session uses one port: **8080**.

This is not a Roblox web client. Roblox runs inside Sober in the Linux container and Selkies streams the desktop to your browser.

## Quick start — Docker Compose

You need a Docker host with Docker Compose v2.

1. Copy this repository to your Docker host.
2. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` and replace the example password with a long, unique password.
4. Start Puffbloc:

   ```bash
   docker compose up -d --build
   ```

   Or run `bash run.sh` to create the example `.env` if needed, validate the Compose configuration, and start the container.

5. Open **http://localhost:8080** (or the host's public URL) and sign in with the username and password from `.env`.

On first startup, Puffbloc downloads and installs Sober from Flathub. This can take several minutes. The Sober window should open automatically after installation. Sober may then show its own first-run Roblox setup; choose its automatic installation option.

### Hosting behind a public URL

For a cloud/container host, deploy the Dockerfile or Compose service and expose container port **8080**. Configure the provider's HTTPS proxy to forward to port 8080.

The Compose file disables Selkies' built-in HTTPS because it is intended to sit behind the provider's HTTPS proxy. Do not expose the plain HTTP container port directly to the public internet. Use a strong password.

## Configuration

| Setting | Default | Purpose |
|---|---|---|
| `WEB_USER` | `puffbloc` | Browser login username |
| `WEB_PASSWORD` | Required | Browser login and desktop password |
| `WEB_PORT` | `8080` | Host-side port |
| `PUFFBLOC_AUTO_START` | `1` | Automatically launch Sober when the desktop starts; set to `0` to open the desktop first |

The container's internal port remains 8080.

## GPU acceleration

Installing Mesa or Vulkan packages cannot create a GPU. The Docker host must actually expose a compatible GPU to the container.

### Intel or AMD integrated/dedicated graphics

On a Linux Docker host with `/dev/dri/renderD128`, find the render-node group ID:

```bash
stat -c '%g' /dev/dri/renderD128
```

Then start with the optional GPU override, replacing `RENDER_GID` with that number:

```bash
RENDER_GID=109 docker compose -f compose.yaml -f compose.gpu.yaml up -d --build
```

The number `109` above is only an example; use the value returned by your host.

### NVIDIA

NVIDIA requires the host's NVIDIA driver and NVIDIA Container Toolkit. The host must permit GPU passthrough; adding packages inside Puffbloc alone is not enough. See the [Selkies GPU setup guide](https://docs.selkies.io/latest/start/).

### Check whether Selkies can see the GPU

```bash
docker compose exec puffbloc selkies gpu-probe
```

A provider that does not expose `/dev/dri` or an NVIDIA GPU will use software rendering instead. Software rendering is useful for testing the browser session, but it is not a substitute for a real GPU for Roblox.

## Sober requirements and host limits

Sober's published requirements include:

- AMD64/x86-64 CPU (ARM is not supported)
- Linux kernel 5.11 or newer
- SSE4.1 and OpenGL ES 3.0 as minimums
- SSE4.2 and Vulkan 1.1 recommended

The Flatpak sandbox also needs to work inside the container. Some managed container hosts restrict user namespaces or other sandbox features; on those hosts Sober may fail to start even if the desktop itself loads.

A 1–1.5 GB RAM container is not a reliable gaming target. The Selkies documentation recommends 2 GB of shared memory for its desktop/browser workload, and Roblox plus video encoding needs additional CPU and memory. A host with an exposed GPU, more RAM, and sufficient CPU headroom is strongly preferred.

## Persistence and logs

Compose creates two named volumes:

- `puffbloc-flatpak` — Sober and Flatpak runtime installation
- `puffbloc-data` — Sober settings and downloaded Roblox data

The Sober startup log is inside the container:

```bash
docker compose exec puffbloc tail -n 100 /home/ubuntu/.cache/puffbloc/sober-startup.log
```

Container logs:

```bash
docker compose logs -f puffbloc
```

Stop Puffbloc:

```bash
docker compose down
```

The named volumes are retained by `docker compose down`. To erase the Sober installation and its saved data too, use `docker compose down -v`.

## Troubleshooting

- **Browser page does not load:** check that the host forwards public traffic to container port 8080 and that WebSockets are allowed.
- **Desktop loads but Sober does not:** inspect `sober-startup.log`. The first Flatpak installation needs internet access.
- **Flatpak sandbox / bubblewrap error:** the container host may block user namespaces or sandbox operations. This is a host capability limitation, not something a Dockerfile can safely fix by itself.
- **Sober opens but Roblox does not install:** complete Sober's first-run setup in the browser session and use its automatic installation option.
- **Low FPS or black screen:** run `selkies gpu-probe` and verify the host actually passed a GPU device through.

## Upstream projects

- [Sober](https://sober.vinegarhq.org/) — unofficial Linux Roblox client, distributed through Flathub.
- [Sober installation requirements](https://vinegarhq.org/Sober/Installation.html)
- [Selkies](https://github.com/selkies-project/selkies) — browser-based Linux desktop streaming.
- [Selkies getting started and GPU guide](https://docs.selkies.io/latest/start/)

## Project status

This repository has not yet been validated end-to-end on your chosen hosting provider. A successful image build does not prove that the host allows Flatpak's sandbox, exposes a GPU, or has enough CPU/RAM for smooth gameplay. Test it on the target host before relying on it.
