#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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

DATA_ROOT="$(read_env DATA_ROOT /srv/media/data)"

echo "Containers"
docker compose ps

echo
echo "Armazenamento"
df -h "$DATA_ROOT"

USAGE="$(df -P "$DATA_ROOT" | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')"
if [[ "$USAGE" =~ ^[0-9]+$ ]] && (( USAGE >= 90 )); then
  echo "ATENÇÃO: o filesystem de mídia está ${USAGE}% ocupado." >&2
fi

echo
echo "GPU Intel"
if [[ -e /dev/dri/renderD128 ]]; then
  ls -l /dev/dri
else
  echo "ATENÇÃO: /dev/dri/renderD128 não foi encontrado." >&2
fi
