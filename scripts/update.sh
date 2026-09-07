#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || {
  echo "Erro: arquivo .env não encontrado." >&2
  exit 1
}

docker compose config --quiet
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
