#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /caminho/do/backup" >&2
  exit 1
fi

[[ -f .env ]] || {
  echo "Erro: arquivo .env não encontrado." >&2
  exit 1
}

read_env() {
  local key="$1"
  local fallback="$2"
  local value
  value="$(sed -n "s/^${key}=//p" .env | tail -n 1)"
  printf '%s' "${value:-$fallback}"
}

CONFIG_ROOT="$(read_env CONFIG_ROOT /srv/media/config)"
BACKUP_DIR="$(realpath -m "$1")"
CONFIG_REAL="$(realpath -m "$CONFIG_ROOT")"

case "$BACKUP_DIR/" in
  "$CONFIG_REAL"/*)
    echo "Erro: o destino não pode ficar dentro de CONFIG_ROOT." >&2
    exit 1
    ;;
esac

mkdir -p "$BACKUP_DIR"
ARCHIVE="$BACKUP_DIR/media-server-$(date +%Y%m%d-%H%M%S).tar.gz"
mapfile -t RUNNING_SERVICES < <(docker compose ps --status running --services)

restore_services() {
  if (( ${#RUNNING_SERVICES[@]} > 0 )); then
    docker compose start "${RUNNING_SERVICES[@]}" >/dev/null
  fi
}
trap restore_services EXIT

if (( ${#RUNNING_SERVICES[@]} > 0 )); then
  docker compose stop "${RUNNING_SERVICES[@]}"
fi

tar -czf "$ARCHIVE" \
  -C "$ROOT_DIR" .env \
  -C "$(dirname "$CONFIG_REAL")" "$(basename "$CONFIG_REAL")"

trap - EXIT
restore_services

echo "Backup criado: $ARCHIVE"
echo "A biblioteca de mídia não foi incluída."
