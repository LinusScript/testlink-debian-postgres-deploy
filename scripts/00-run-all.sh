#!/usr/bin/env bash
# Fuehrt die Schritte 1-4 nacheinander aus (Server vorbereiten, Apache/PHP,
# PostgreSQL, TestLink deployen). Der Web-Installer (Schritt 5) bleibt manuell
# im Browser - siehe docs/installation/07-web-installer.md.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./01-prepare-system.sh
./02-install-apache-php.sh
./03-install-postgresql.sh
./04-deploy-testlink.sh

echo -e "\nAlle automatisierten Schritte abgeschlossen."
echo "Weiter mit docs/installation/07-web-installer.md im Browser."
