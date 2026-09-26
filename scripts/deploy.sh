#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--add-ons" ) ]]; then
  echo "Uso: $0 [--add-ons]" >&2
  exit 1
fi

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

command -v python3 >/dev/null || {
  echo "Erro: instale python3 para interpretar a configuração do Compose." >&2
  exit 1
}

# Use the effective Compose values, including quoted .env values and overrides.
COMPOSE_JSON="$(docker compose config --format json)"
RESOLVED="$(printf '%s' "$COMPOSE_JSON" | python3 -c '
import json, os, sys
c = json.load(sys.stdin)
def volume(service, target):
    return next(v["source"] for v in c["services"][service]["volumes"] if v["target"] == target)
def port(service, target):
    return next(str(p["published"]) for p in c["services"][service]["ports"] if p["target"] == target)
print(c["name"])
print(os.path.dirname(volume("emby", "/config")))
print(volume("qbittorrent", "/data"))
print(port("emby", 8096))
print(port("homepage", 3000))
')"
mapfile -t VALUES <<< "$RESOLVED"
PROJECT_NAME="${VALUES[0]}"
CONFIG_ROOT="${VALUES[1]}"
DATA_ROOT="${VALUES[2]}"
EMBY_PORT="${VALUES[3]}"
HOMEPAGE_PORT="${VALUES[4]}"

docker info >/dev/null
# shellcheck source=scripts/lib/emby-migration.sh
source "$ROOT_DIR/scripts/lib/emby-migration.sh"

mkdir -p \
  "$CONFIG_ROOT/qbittorrent" \
  "$CONFIG_ROOT/prowlarr" \
  "$CONFIG_ROOT/radarr" \
  "$CONFIG_ROOT/sonarr" \
  "$CONFIG_ROOT/bazarr" \
  "$CONFIG_ROOT/emby" \
  "$CONFIG_ROOT/seerr" \
  "$DATA_ROOT/torrents/incomplete" \
  "$DATA_ROOT/torrents/movies" \
  "$DATA_ROOT/torrents/tv" \
  "$DATA_ROOT/library/movies" \
  "$DATA_ROOT/library/tv"

docker compose config --quiet
if [[ "${1:-}" == "--add-ons" ]]; then
  docker compose pull bazarr seerr
  docker compose up -d --no-deps --pull never bazarr seerr homepage
else
  command -v curl >/dev/null || { echo "Erro: instale curl antes do deploy." >&2; exit 1; }
  prepare_emby_migration
  docker compose up -d
  wait_for_emby
  finish_emby_migration
fi

echo
docker compose ps
echo
echo "Emby: http://$(hostname -I | awk '{print $1}'):$EMBY_PORT"
echo "Homepage: http://$(hostname -I | awk '{print $1}'):$HOMEPAGE_PORT"
