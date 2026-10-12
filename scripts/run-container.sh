#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s <compose.yml>\n' "${0##*/}" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

compose_file=$1

if [[ ! -f "$compose_file" ]]; then
  printf 'Error: compose file not found: %s\n' "$compose_file" >&2
  exit 1
fi

if ! command -v podman-compose >/dev/null 2>&1; then
  printf 'Error: podman-compose is not installed or not on PATH.\n' >&2
  exit 127
fi

exec podman-compose -f "$compose_file" up -d