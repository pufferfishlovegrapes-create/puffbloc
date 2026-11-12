# Puffbloc — Sober in your browser

Puffbloc is an experimental, single-container setup intended to run **Sober** (the unofficial Linux Roblox client) and stream its Linux desktop to a web browser using **Selkies**.

It is not a Roblox web client. Roblox runs inside Sober in the Linux container; Selkies streams the screen and forwards keyboard/mouse/gamepad input to the browser.

## Deploy

Build the repository as a Docker image and deploy it with:

- Container port: `8080`
- Environment variable: `WEB_PASSWORD` (required, at least 12 characters)
- Optional: `WEB_USER` (defaults to `puffbloc`)
- Optional: `PORT` (defaults to `8080`, use the port expected by your host)

The host's HTTPS reverse proxy should forward to container port 8080. This image serves HTTP internally because many container platforms terminate HTTPS at their proxy.

After opening the public URL, sign in with the `WEB_USER` and `WEB_PASSWORD` values. Sober is configured to launch automatically. On first launch, complete Sober's Roblox setup inside the browser session.

## GPU access

Sober needs compatible graphics support. The image includes Mesa and Vulkan userspace libraries, but these do not create a GPU.

For an Intel or AMD host, Docker normally needs the host's DRM device passed through (usually `/dev/dri`) and permission for the container user to access the render node. A provider that does not expose a GPU may fall back to software rendering, which can be very slow or fail.

Sober's documented minimums include an x86-64 CPU, Linux kernel 5.11 or newer, and OpenGL ES 3.0-capable graphics. Vulkan 1.1 is recommended. The container uses the host kernel; it cannot upgrade it.

## Persistence

Mount a persistent volume at:

`/home/sober/.var/app`

This preserves Sober's app data and Roblox download between restarts.

## Important experimental limitations

- **Not yet validated end-to-end.** A successful Docker build does not prove Flatpak sandboxing, Sober launch, GPU acceleration, audio, or browser input work on a particular host.
- Sober is distributed officially as a Flatpak. Flatpak's sandbox depends on Linux namespace and container permissions; some managed hosting platforms restrict these. If Sober exits immediately, inspect `/home/sober/sober.log` and the container logs.
- The initial image uses Selkies' AppImage and an Openbox session rather than the Selkies desktop container. This avoids relying on Flatpak inside the upstream Selkies desktop image, whose documentation says not to use Flatpak/Snap/systemd there.
- NVIDIA passthrough needs matching host driver support and is not configured automatically by this generic image.
- The container must run on AMD64/x86-64. Sober does not currently support ARM64.
- Browser streaming adds CPU and memory overhead. The previously discussed 1–1.5 GB RAM target may be too tight; test before choosing a small host.
- Do not expose this service publicly without a strong password and HTTPS at the hosting proxy.

## Local build

```bash
docker build -t puffbloc .
docker run --rm -p 8080:8080 \
  -e WEB_USER=puffbloc \
  -e WEB_PASSWORD='use-a-long-unique-password' \
  --device=/dev/dri \
  --shm-size=1g \
  puffbloc
```

If the host has no `/dev/dri`, omit `--device=/dev/dri`; that does not provide hardware acceleration.

## Upstream projects

- [Sober](https://sober.vinegarhq.org/) — unofficial Linux Roblox client, distributed through Flathub.
- [Selkies](https://github.com/selkies-project/selkies) — browser-based Linux desktop streaming.
