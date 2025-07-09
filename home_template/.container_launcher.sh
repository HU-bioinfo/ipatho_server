#!/bin/bash

set -e

USER_HOME="$HOME"
CONTAINER_DIR="$USER_HOME/container"
DEVCONTAINER_CONFIG="$CONTAINER_DIR/.devcontainer/devcontainer.json"
DOCKER_COMPOSE_FILE="$CONTAINER_DIR/.devcontainer/docker-compose.yml"

[[ ! -f "$DEVCONTAINER_CONFIG" ]] && { echo "Error: $DEVCONTAINER_CONFIG not found"; exit 1; }
[[ ! -f "$DOCKER_COMPOSE_FILE" ]] && { echo "Error: $DOCKER_COMPOSE_FILE not found"; exit 1; }

DOCKER_IMAGE=$(jq -r '.image // "ubuntu:latest"' "$DEVCONTAINER_CONFIG")
sed -i "s/{{DOCKER_IMAGE}}/$DOCKER_IMAGE/g" "$DOCKER_COMPOSE_FILE"

CONTAINER_NAME="devcontainer-$(basename "$USER_HOME")"

if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    podman stop "$CONTAINER_NAME" 2>/dev/null || true
    podman rm "$CONTAINER_NAME" 2>/dev/null || true
fi

cd "$CONTAINER_DIR/.devcontainer"
podman-compose up -d

podman exec -it "$CONTAINER_NAME" /bin/bash

trap 'podman stop "$CONTAINER_NAME" 2>/dev/null || true' EXIT