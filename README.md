# PuffBloc — Headless Linux + Sober

This repository builds a lightweight Ubuntu container that starts Sober in a minimal Openbox session and exposes the screen through noVNC in a web browser.

## Important graphics limitation

Sober is a graphical application. This image provides a virtual VNC display, but that alone does **not** guarantee hardware acceleration. A host must provide compatible graphics support for Sober. If the host supports Intel/AMD GPU device passthrough, expose its DRM devices (usually `/dev/dri`) to the container. Without a usable GPU, Mesa may fall back to software rendering, which can be slow or may not work with Sober.

Sober's compatibility also depends on the host CPU and Linux kernel. A container cannot upgrade the host kernel.

## Build

```bash
docker build -t puffbloc .
```

## Run

```bash
docker run -d \
  --name puffbloc \
  -p 6080:6080 \
  -e VNC_PASSWORD='choose-a-long-password' \
  --device=/dev/dri:/dev/dri \
  puffbloc
```

The `--device` option is for hosts that actually have `/dev/dri`. If the host has no GPU device, remove that option; this does not add a GPU.

Open `http://HOST:6080/vnc.html` and connect using the VNC password. In production, put the service behind HTTPS and do not expose an unauthenticated VNC endpoint directly to the public internet.

## Environment variables

- `VNC_PASSWORD` — required; at least 8 characters. TigerVNC's traditional password authentication uses only the first 8 characters.
- `RESOLUTION` — virtual screen size; defaults to `1280x720`.
- `NOVNC_PORT` — browser/noVNC port; defaults to `6080`.

## What this currently does

- Ubuntu 24.04 base.
- Installs Sober from the official Flathub package `org.vinegarhq.Sober`.
- Starts a minimal Openbox session inside TigerVNC.
- Exposes the remote screen through noVNC on port 6080.

This is an initial deployment baseline, not a guarantee that Sober will launch on every VPS or container host. Validate GPU access and Sober compatibility on the chosen host before relying on it.
