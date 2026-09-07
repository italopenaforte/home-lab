#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if (( EUID == 0 )); then
  echo "Erro: execute como usuário normal; o script pedirá sudo quando necessário." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Erro: não foi possível identificar o sistema operacional." >&2
  exit 1
fi

# Informações fornecidas pelo próprio sistema operacional.
# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Erro: este instalador suporta somente Ubuntu Server." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "Erro: sudo não está instalado." >&2
  exit 1
fi

echo "Preparando ${PRETTY_NAME:-Ubuntu} para o servidor de mídia..."
sudo -v
sudo apt-get update
sudo apt-get install -y ca-certificates curl git vainfo intel-gpu-tools

DOCKER_WAS_INSTALLED=false
if docker compose version >/dev/null 2>&1; then
  DOCKER_WAS_INSTALLED=true
  echo "Docker Engine e Compose já estão disponíveis; mantendo a instalação atual."
elif command -v docker >/dev/null 2>&1; then
  echo "Erro: existe uma instalação parcial do Docker sem Compose." >&2
  echo "Corrija ou remova essa instalação antes de executar o script novamente." >&2
  exit 1
else
  CONFLICTS=()
  for package in docker.io docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'; then
      CONFLICTS+=("$package")
    fi
  done

  if (( ${#CONFLICTS[@]} > 0 )); then
    echo "Erro: pacotes conflitantes encontrados: ${CONFLICTS[*]}" >&2
    echo "O script não os removerá automaticamente para evitar perda de configuração." >&2
    exit 1
  fi

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  ARCHITECTURE="$(dpkg --print-architecture)"
  CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [[ -z "$CODENAME" ]]; then
    echo "Erro: não foi possível determinar o codinome do Ubuntu." >&2
    exit 1
  fi

  DOCKER_SOURCE="Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/docker.asc"
  printf '%s\n' "$DOCKER_SOURCE" | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null

  sudo apt-get update
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin
  sudo systemctl enable --now docker
fi

sudo usermod -aG docker "$USER"

PUID_VALUE="$(id -u)"
PGID_VALUE="$(id -g)"
RENDER_GID_VALUE="$(getent group render | cut -d: -f3 || true)"
VIDEO_GID_VALUE="$(getent group video | cut -d: -f3 || true)"

sudo install -d -o "$PUID_VALUE" -g "$PGID_VALUE" /srv/media
mkdir -p /srv/media/config /srv/media/data

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '%s=%s\n' "$key" "$value" >> .env
  fi
}

set_env_value PUID "$PUID_VALUE"
set_env_value PGID "$PGID_VALUE"
[[ -n "$RENDER_GID_VALUE" ]] && set_env_value RENDER_GID "$RENDER_GID_VALUE"
[[ -n "$VIDEO_GID_VALUE" ]] && set_env_value VIDEO_GID "$VIDEO_GID_VALUE"

echo
if [[ ! -e /dev/dri/renderD128 ]]; then
  echo "ATENÇÃO: /dev/dri/renderD128 não foi encontrado."
  echo "Verifique firmware, kernel e GPU antes de executar o deploy."
elif [[ -z "$RENDER_GID_VALUE" || -z "$VIDEO_GID_VALUE" ]]; then
  echo "ATENÇÃO: não foi possível descobrir os grupos render/video."
  echo "Confira esses valores manualmente no arquivo .env."
else
  echo "GPU Intel detectada e IDs gravados no .env."
fi

echo
echo "Preparação concluída."
if [[ "$DOCKER_WAS_INSTALLED" == false ]] || ! id -nG | tr ' ' '\n' | grep -qx docker; then
  echo "Saia da sessão e entre novamente para ativar o grupo docker."
fi
echo "Depois execute: ./scripts/deploy.sh"
