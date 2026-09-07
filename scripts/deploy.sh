#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Erro: Docker não está instalado." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Erro: o plugin Docker Compose não está disponível." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Erro: copie .env.example para .env e revise os valores." >&2
  exit 1
fi

if [[ ! -d /dev/dri ]]; then
  echo "Erro: /dev/dri não existe; habilite a GPU Intel antes do deploy." >&2
  exit 1
fi

read_env() {
  local key="$1"
  local fallback="$2"
  local value
  value="$(sed -n "s/^${key}=//p" .env | tail -n 1)"
  printf '%s' "${value:-$fallback}"
}

CONFIG_ROOT="$(read_env CONFIG_ROOT /srv/media/config)"
DATA_ROOT="$(read_env DATA_ROOT /srv/media/data)"

mkdir -p \
  "$CONFIG_ROOT/qbittorrent" \
  "$CONFIG_ROOT/prowlarr" \
  "$CONFIG_ROOT/radarr" \
  "$CONFIG_ROOT/sonarr" \
  "$CONFIG_ROOT/jellyfin" \
  "$CONFIG_ROOT/jellyfin-cache" \
  "$DATA_ROOT/torrents/incomplete" \
  "$DATA_ROOT/torrents/movies" \
  "$DATA_ROOT/torrents/tv" \
  "$DATA_ROOT/library/movies" \
  "$DATA_ROOT/library/tv"

docker compose config --quiet
docker compose up -d --remove-orphans

echo
docker compose ps
echo
echo "Jellyfin: http://$(hostname -I | awk '{print $1}'):$(read_env JELLYFIN_PORT 8096)"
