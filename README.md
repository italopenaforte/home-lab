# 🏠 Home Lab

Personal home lab infrastructure managed with Docker Compose.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         Proxmox VE                           │
│  ┌──────────────────────────┐  ┌──────────────────────────┐  │
│  │   VM 100 (Docker)        │  │   VM 101 (Docker/GPU)    │  │
│  │                          │  │                          │  │
│  │  ├── Traefik             │  │  └── LLM (Ollama +       │  │
│  │  ├── Pi-hole             │  │       Open WebUI)        │  │
│  │  ├── Media Stack         │  │                          │  │
│  │  ├── Portainer           │  └──────────────────────────┘  │
│  │  ├── Stirling-PDF        │                                │
│  │  ├── Uptime Kuma         │  ┌──────────────────────────┐  │
│  │  ├── Homepage            │  │   TrueNAS                │  │
│  │  ├── Vaultwarden         │  └──────────────────────────┘  │
│  │  ├── Watchtower          │                                │
│  │  ├── Dozzle              │                                │
│  │  ├── Speedtest Tracker   │                                │
│  │  └── RTSP-to-Web         │                                │
│  └──────────────────────────┘                                │
└──────────────────────────────────────────────────────────────┘
```

## Stacks

| Stack | Description | Ports |
|-------|-------------|-------|
| **traefik** | Reverse proxy with Cloudflare DNS & Let's Encrypt | `80`, `443` |
| **pihole** | DNS server with Pi-hole + Cloudflared (DoH) | `53`, `67`, `500` |
| **media** | Media automation (Plex, Sonarr, Radarr, Prowlarr, qBittorrent, Overseerr, Flaresolverr) | Multiple |
| **portainer** | Docker container management UI | `9000`, `9443` |
| **stirling-pdf** | PDF manipulation tools | `8085` |
| **llm** | Local LLM with Ollama + Open WebUI (GPU) | `3000`, `11434` |
| **rtsp-to-web** | RTSP camera stream to web viewer | `8083` (host network) |
| **uptime-kuma** | Service monitoring & status page | `3001` |
| **homepage** | Dashboard — central launch page for all services | `3010` |
| **vaultwarden** | Self-hosted Bitwarden password manager | `8222` |
| **watchtower** | Auto-update Docker containers (runs daily at 4 AM) | — |
| **dozzle** | Real-time Docker log viewer | `9999` |
| **speedtest-tracker** | Automated internet speed monitoring | `8765` |

## Deployment Order

1. **Traefik** — Reverse proxy must be up first (handles SSL/routing via `config.yml`)
2. **Pi-hole** — DNS resolution for the network
3. **Portainer** — Container management (helps monitor the rest)
4. **Watchtower** — Auto-updates (set and forget)
5. **Uptime Kuma** — Start monitoring everything from here on
6. **Media Stack** — All media services together
7. **Everything else** — Stirling-PDF, LLM, Vaultwarden, Dozzle, Homepage, Speedtest Tracker, RTSP-to-Web
8. **Homepage** — Deploy last so all services are already up for the dashboard

## Prerequisites

- Docker & Docker Compose installed
- For the **LLM stack**: NVIDIA GPU + CUDA drivers (see [docs/nvidia-cuda-setup.md](docs/nvidia-cuda-setup.md))
- For **Pi-hole**: DNS port fix on Ubuntu (see [docs/fix-dns-ubuntu.md](docs/fix-dns-ubuntu.md))
- For **Proxmox VM auto-start**: see [docs/proxmox-vm-autostart.md](docs/proxmox-vm-autostart.md)

## Quick Start

```bash
# Deploy Traefik first
cd stacks/traefik
docker compose up -d

# Then deploy any stack
cd stacks/<stack-name>
docker compose up -d
```

## Directory Structure

```
home-lab/
├── README.md
├── .env.example
├── docs/                    # Setup guides and troubleshooting
├── stacks/                  # Production Docker Compose stacks
│   ├── traefik/
│   ├── pihole/
│   ├── media/
│   ├── portainer/
│   ├── stirling-pdf/
│   ├── llm/
│   ├── rtsp-to-web/
│   ├── uptime-kuma/
│   ├── homepage/
│   ├── vaultwarden/
│   ├── watchtower/
│   ├── dozzle/
│   └── speedtest-tracker/
└── templates/               # Reference configs (not production)
    └── pihole-unbound/
```

## Environment Variables

Copy `.env.example` and fill in your values:

```bash
cp .env.example .env
```

## References

- [Traefik v3 Docs](https://doc.traefik.io/traefik/)
- [Pi-hole Docker](https://github.com/pi-hole/docker-pi-hole)
- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [Servarr Wiki](https://wiki.servarr.com/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Homepage](https://gethomepage.dev/)
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
- [Watchtower](https://containrrr.dev/watchtower/)
- [Dozzle](https://dozzle.dev/)
- [Speedtest Tracker](https://github.com/linuxserver/docker-speedtest-tracker)
