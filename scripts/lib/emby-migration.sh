# Sourced by deploy.sh after resolving the Compose configuration.
MIGRATING=false
JELLYFIN_ID=""

migration_realpath() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

prepare_emby_migration() {
  local old_project old_config
  JELLYFIN_ID="$(docker ps -aq --filter 'name=^/jellyfin$')"
  [[ -n "$JELLYFIN_ID" ]] || return 0

  old_project="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$JELLYFIN_ID")"
  if [[ "$old_project" != "$PROJECT_NAME" ]]; then
    echo "Erro: o container jellyfin pertence a outro projeto ($old_project)." >&2
    return 1
  fi
  command -v curl >/dev/null || { echo "Erro: instale curl antes da migração." >&2; return 1; }
  old_config="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/config"}}{{.Source}}{{end}}{{end}}' "$JELLYFIN_ID")"
  if [[ -z "$old_config" || ! -d "$old_config" || "$(migration_realpath "$old_config")" != "$(migration_realpath "$CONFIG_ROOT/jellyfin")" ]]; then
    echo "Erro: a configuração do Jellyfin não corresponde a CONFIG_ROOT/jellyfin. Confira o .env." >&2
    return 1
  fi

  echo "Substituindo o container Jellyfin pelo Emby..."
  # Download before stopping playback; network failures leave Jellyfin running.
  docker compose pull emby homepage
  docker stop "$JELLYFIN_ID"
  docker rm "$JELLYFIN_ID"
  MIGRATING=true
}

wait_for_emby() {
  local attempt
  echo "Aguardando a interface do Emby (até aproximadamente 3 minutos)..."
  for (( attempt=0; attempt<36; attempt++ )); do
    if curl --noproxy '*' -fsS --max-time 3 "http://127.0.0.1:$EMBY_PORT/web/index.html" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  docker compose logs --tail=50 emby >&2 || true
  echo "Erro: Emby não respondeu. Confira os logs acima e execute o deploy novamente após corrigir a causa." >&2
  return 1
}

finish_emby_migration() {
  [[ "$MIGRATING" == true ]] || return 0
  echo "Container Jellyfin removido; Emby iniciado."
  echo "Conclua o assistente do Emby e reconecte o Seerr em http://emby:8096."
}
