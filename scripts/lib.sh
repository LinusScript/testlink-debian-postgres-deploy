#!/usr/bin/env bash
# Gemeinsame Hilfsfunktionen fuer die scripts/*.sh Dateien.
# Wird per `source` eingebunden, nicht direkt ausgefuehrt.

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Bitte als root ausfuehren (z.B. mit sudo)." >&2
    exit 1
  fi
}

load_env() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  local env_file="${script_dir}/../.env"
  if [[ ! -f "${env_file}" ]]; then
    echo "Keine .env gefunden unter ${env_file}. Bitte '.env.example' nach '.env' kopieren und anpassen." >&2
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "${env_file}"
  set +a
}

log() {
  echo -e "\n\033[1;32m==>\033[0m $*"
}
