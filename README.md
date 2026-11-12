# Puffbloc — Sober in your browser

Puffbloc is an experimental single-container setup intended to run **Sober** (the unofficial Linux Roblox client) and stream its Linux desktop to a web browser using **Selkies**.

It is not a Roblox web client. Roblox runs inside Sober in the Linux container; Selkies streams the screen and forwards keyboard, mouse and gamepad input to the browser.

## What happens when the container starts

1. The entrypoint checks that a browser-login password is set.
2. A system D-Bus service is started for Flatpak.
3. Selkies starts an XFCE session with its own virtual display and audio server.
4. XFCE autostart launches Sober.
5. Selkies serves the desktop on port 8080. The host should provide HTTPS.

On first launch, Sober may ask you to complete its initial setup inside the browser session. Allow time for the first startup and Roblox download.

## Deploy

Build the repository as a Docker image and deploy it with:

- Container port: `8080`
- Environment variable: `WEB_PASSWORD` (required, at least 12 characters)
- Optional: `WEB_USER` (defaults to `puffbloc`)
- Optional: `PORT` (defaults to `8080`, use the port expected by your host)

The host's HTTPS reverse proxy should forward to container port 8080. This image serves HTTP internally because many container platforms terminate HTTPS at their proxy.

After opening the public URL, sign in with the `WEB_USER` and `WEB_PASSWORD` values.

## GPU requirements

The image includes Mesa and Vulkan userspace packages, but these do not create or guarantee a GPU.

For Intel or AMD graphics, the host must expose a compatible DRM render device (usually `/dev/dri/renderD128`) to the container, and the container user must have permission to open it. A provider that hides GPU devices cannot provide hardware acceleration just because Mesa is installed.

For NVIDIA, the host needs NVIDIA Container Toolkit and a compatible driver/runtime configuration; this generic image does not configure NVIDIA passthrough automatically.

Sober's documented requirements include an AMD64/x86-64 CPU with SSE4.1 and OpenGL ES 3.0-capable graphics. SSE4.2 and Vulkan 1.1 are recommended. The container uses the host kernel; it cannot upgrade it.

## Persistence

Mount a persistent volume at:

`/home/sober/.var/app`

This preserves Sober's Flatpak app data and downloaded Roblox files between container restarts.

## Local build and run

```bash
docker build -t puffbloc .
docker run --rm -p 8080:8080 \
  -e WEB_USER=puffbloc \
  -e WEB_PASSWORD='use-a-long-unique-password' \
  --device=/dev/dri \
  --group-add "$(stat -c %g /dev/dri/renderD128)" \
  --shm-size=2g \
  -v puffbloc-data:/home/sober/.var/app \
  puffbloc
```

The `--device` and `--group-add` options above are for an Intel/AMD Linux host where `/dev/dri/renderD128` exists. If the host has no render device, remove both options; Sober may then fail or fall back to slow software rendering.

Selkies recommends 2 GB of shared memory for its desktop browser workload. This is a shared-memory limit, not a promise that the game will fit within 1–1.5 GB of total RAM. Roblox and the streaming encoder both need memory and CPU. A small 1–1.5 GB host is not a reliable target; test on the actual provider before committing to it.

## Health check and logs

The Docker health check verifies that Selkies' HTTP endpoint responds. It does **not** prove that Sober launched or that GPU acceleration works.

Useful checks inside the container:

```bash
cat /home/sober/sober.log
ls -l /dev/dri
```

If the browser page loads but Sober does not, inspect the Sober log and container logs separately.

## Experimental limitations

- This has not yet been validated end-to-end. A successful Docker build does not prove Flatpak sandboxing, Sober launch, GPU acceleration, audio, gamepad input or browser control work on a particular host.
- Some managed container hosts restrict Flatpak's sandbox requirements or do not expose GPU devices.
- The image targets AMD64/x86-64. Sober does not currently support ARM64.
- The Selkies AppImage version is pinned to 2.1.0 for reproducible builds; update it deliberately after checking upstream release notes.
- Do not expose this service publicly without a strong password and HTTPS at the hosting proxy.

## Upstream projects

- [Sober](https://sober.vinegarhq.org/) — unofficial Linux Roblox client, distributed through Flathub.
- [Selkies](https://github.com/selkies-project/selkies) — browser-based Linux desktop streaming.
