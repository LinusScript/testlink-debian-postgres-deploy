#!/usr/bin/env bash
# Nach erfolgreicher Installation: install/-Verzeichnis sperren.
# Siehe docs/installation/09-hardening-and-prod.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

require_root
load_env

TL_INSTALL_DIR="${TL_INSTALL_DIR:-/var/www/testlink}"
INSTALL_SUBDIR="${TL_INSTALL_DIR}/install"
DISABLED_SUBDIR="${TL_INSTALL_DIR}/install.DISABLED"

if [[ -d "${INSTALL_SUBDIR}" ]]; then
  mv "${INSTALL_SUBDIR}" "${DISABLED_SUBDIR}"
  log "install/ wurde nach install.DISABLED/ umbenannt."
elif [[ -d "${DISABLED_SUBDIR}" ]]; then
  log "install/ ist bereits gesperrt (install.DISABLED/ existiert schon)."
else
  echo "Weder install/ noch install.DISABLED/ gefunden unter ${TL_INSTALL_DIR}." >&2
  exit 1
fi

log "Schreibrechte einschraenken (nur upload_area, gui/templates_c, logs bleiben beschreibbar)"
find "${TL_INSTALL_DIR}" -type d -exec chmod 755 {} \;
find "${TL_INSTALL_DIR}" -type f -exec chmod 644 {} \;
chown -R www-data:www-data \
  "${TL_INSTALL_DIR}/upload_area" \
  "${TL_INSTALL_DIR}/gui/templates_c" \
  "${TL_INSTALL_DIR}/logs" 2>/dev/null || true

if [[ -f "${TL_INSTALL_DIR}/config_db.inc.php" ]]; then
  chmod 640 "${TL_INSTALL_DIR}/config_db.inc.php"
  chown www-data:www-data "${TL_INSTALL_DIR}/config_db.inc.php"
  log "config_db.inc.php auf 640/www-data gesetzt."
fi

log "Fertig. Siehe docs/installation/09-hardening-and-prod.md fuer weitere Schritte (TLS etc.)."
