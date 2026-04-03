#!/bin/bash
set -e

# ============================================================================
# Home Lab — Deploy All Stacks
# Usage: ./deploy.sh [up|down|restart|status|pull]
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STACKS_DIR="$SCRIPT_DIR/stacks"

# Deploy order matters — dependencies first
STACKS=(
  portainer
  watchtower
  uptime-kuma
  media
  vaultwarden
  speedtest-tracker
  homepage          # Last — so all services are up for the dashboard
)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# LLM stack is on a separate GPU machine — skip by default
SKIP_STACKS=()

should_skip() {
  local stack="$1"
  for skip in "${SKIP_STACKS[@]}"; do
    [[ "$stack" == "$skip" ]] && return 0
  done
  return 1
}

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  🏠 Home Lab — $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

deploy_stack() {
  local stack="$1"
  local action="$2"
  local compose_file="$STACKS_DIR/$stack/docker-compose.yaml"

  if [[ ! -f "$compose_file" ]]; then
    echo -e "  ${YELLOW}⚠ $stack — compose file not found, skipping${NC}"
    return
  fi

  if should_skip "$stack"; then
    echo -e "  ${YELLOW}⏭ $stack — skipped (in SKIP_STACKS)${NC}"
    return
  fi

  case "$action" in
    up)
      echo -e "  ${GREEN}▶ $stack${NC} — starting..."
      docker compose -f "$compose_file" up -d --quiet-pull 2>&1 | sed 's/^/    /'
      echo -e "  ${GREEN}✓ $stack${NC} — running"
      ;;
    down)
      echo -e "  ${RED}■ $stack${NC} — stopping..."
      docker compose -f "$compose_file" down 2>&1 | sed 's/^/    /'
      echo -e "  ${RED}✓ $stack${NC} — stopped"
      ;;
    restart)
      echo -e "  ${YELLOW}↻ $stack${NC} — restarting..."
      docker compose -f "$compose_file" restart 2>&1 | sed 's/^/    /'
      echo -e "  ${YELLOW}✓ $stack${NC} — restarted"
      ;;
    pull)
      echo -e "  ${BLUE}⬇ $stack${NC} — pulling latest images..."
      docker compose -f "$compose_file" pull --quiet 2>&1 | sed 's/^/    /'
      echo -e "  ${BLUE}✓ $stack${NC} — updated"
      ;;
    status)
      echo -e "  ${BLUE}● $stack${NC}"
      docker compose -f "$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>&1 | sed 's/^/    /'
      ;;
  esac
}

# --- Main ---

ACTION="${1:-up}"

case "$ACTION" in
  up|down|restart|pull|status)
    print_header "$ACTION"

    if [[ "$ACTION" == "down" ]]; then
      # Reverse order for shutdown
      for ((i=${#STACKS[@]}-1; i>=0; i--)); do
        deploy_stack "${STACKS[$i]}" "$ACTION"
      done
    else
      for stack in "${STACKS[@]}"; do
        deploy_stack "$stack" "$ACTION"
      done
    fi

    echo ""
    echo -e "${GREEN}Done!${NC}"
    ;;
  *)
    echo "Usage: $0 [up|down|restart|status|pull]"
    echo ""
    echo "  up       Start all stacks (default)"
    echo "  down     Stop all stacks (reverse order)"
    echo "  restart  Restart all stacks"
    echo "  pull     Pull latest images for all stacks"
    echo "  status   Show status of all stacks"
    exit 1
    ;;
esac
