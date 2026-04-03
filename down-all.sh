#!/bin/bash

# Ensure we're running from the project root
cd "$(dirname "$0")"

echo "==========================================="
echo " Bringing down all active stacks..."
echo "==========================================="
for d in stacks/* ; do
    if [ -f "$d/docker-compose.yaml" ]; then
        echo "--> Taking down stack in $d"
        docker compose -f "$d/docker-compose.yaml" down
    fi
done

echo ""
echo "==========================================="
echo " Cleaning up recently removed services..."
echo "==========================================="
# These are containers we removed from the configuration earlier 
# but might still be running because we didn't stop them before removing the configs.
ORPHANS="cloudflared pihole dozzle rtsp-to-web overseerr traefik llm"

for c in $ORPHANS; do
    # Check if container exists
    if [ "$(docker ps -aq -f name=^/${c}$)" ]; then
        echo "--> Stopping and removing orphaned container: $c"
        docker stop "$c" >/dev/null 2>&1
        docker rm "$c" >/dev/null 2>&1
    fi
done

echo ""
echo "==========================================="
echo " Docker System Prune (cleaning networks, etc)"
echo "==========================================="
# Clean up any unused networks, dangling images, and stopped containers.
# Note: This will now completely remove all unused volumes and unused images!
docker system prune -a --volumes -f

echo ""
echo "All done! Environment is clean."
