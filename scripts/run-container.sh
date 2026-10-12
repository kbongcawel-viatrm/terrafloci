#!/usr/bin/env bash

set -euo pipefail

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

usage() {
    printf 'Usage: %s <compose.yml>\n' "${0##*/}" >&2
}

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

compose_file="$1"

# Validate required commands.
for cmd in podman podman-compose; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf '%sError%s: %s is not installed or not on PATH.\n' \
            "$RED" "$NC" "$cmd" >&2
        exit 127
    fi
done

# Validate compose file.
if [[ ! -f "$compose_file" ]]; then
    printf '%sError%s: compose file not found: %s\n' \
        "$RED" "$NC" "$compose_file" >&2
    exit 1
fi

printf '%sValidating compose file%s: %s\n' \
    "$YELLOW" "$NC" "$compose_file"

podman-compose -f "$compose_file" config >/dev/null

printf '%sPulling compose service images...%s\n' "$YELLOW" "$NC"
podman-compose -f "$compose_file" pull

printf '%sStarting compose services...%s\n' "$GREEN" "$NC"
podman-compose -f "$compose_file" up -d

# Retrieve IDs after starting the services.
container_ids=$(podman-compose -f "$compose_file" ps -q)

if [[ -z "$container_ids" ]]; then
    printf '%sError%s: no containers found for %s\n' \
        "$RED" "$NC" "$compose_file" >&2
    exit 1
fi

printf '%sContainer service is now up!%s\n' "$GREEN" "$NC"

# Display each container.
while IFS= read -r container_id; do
    [[ -z "$container_id" ]] && continue
   podman ps -a --filter "id=$container_id" \
  --format 'Name: {{.Names}} | Status: {{.Status}}'
done <<< "$container_ids"

# for multiple ID's
#while IFS= read -r container_id; do
#    [[ -z "$container_id" ]] && continue
#    podman ps -a --filter "id=$container_id" \
#      --format 'Name: {{.Names}} | Status: {{.Status}}'
#done <<< "$container_ids"
