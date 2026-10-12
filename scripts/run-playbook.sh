#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s <playbook.yml>\n' "${0##*/}" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

playbook=$1

if [[ ! -f "$playbook" ]]; then
  printf 'Error: playbook file not found: %s\n' "$playbook" >&2
  exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  printf 'Error: ansible-playbook is not installed or not on PATH.\n' >&2
  exit 127
fi

exec ansible-playbook "$playbook"