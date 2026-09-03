#!/usr/bin/env bash
# Schritt 1: Basis-System vorbereiten (Debian).
# Siehe docs/installation/01-linux-basics.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

require_root

log "apt-get update && upgrade"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

log "Basis-Werkzeuge installieren"
apt-get install -y curl wget ca-certificates gnupg unzip tar git

log "System vorbereitet."
