#!/usr/bin/env bash
# Schritt 4: TestLink-Quellcode holen, entpacken, Apache-VirtualHost anlegen.
# Siehe docs/installation/05-testlink-source.md und 06-virtualhost.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

require_root
load_env

TL_VERSION="${TL_VERSION:?TL_VERSION muss in .env gesetzt sein}"
TL_INSTALL_DIR="${TL_INSTALL_DIR:-/var/www/testlink}"
TL_DOMAIN="${TL_DOMAIN:-testlink.demo.local}"
TL_HTTP_PORT="${TL_HTTP_PORT:-80}"

TARBALL_URL="https://github.com/TestLinkOpenSourceTRMS/testlink-code/archive/refs/tags/${TL_VERSION}.tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [[ -d "${TL_INSTALL_DIR}" && -n "$(ls -A "${TL_INSTALL_DIR}" 2>/dev/null)" ]]; then
  log "Zielverzeichnis ${TL_INSTALL_DIR} existiert bereits und ist nicht leer - Download/Entpacken wird uebersprungen."
  echo "Falls du neu deployen willst, sichere/loesche das Verzeichnis vorher manuell."
else
  log "TestLink ${TL_VERSION} herunterladen"
  curl -fL "${TARBALL_URL}" -o "${TMP_DIR}/testlink.tar.gz"

  log "Entpacken"
  tar -xzf "${TMP_DIR}/testlink.tar.gz" -C "${TMP_DIR}"
  SRC_DIR="$(find "${TMP_DIR}" -maxdepth 1 -type d -name 'testlink-code-*' | head -n1)"
  if [[ -z "${SRC_DIR}" ]]; then
    echo "Konnte entpacktes Verzeichnis nicht finden." >&2
    exit 1
  fi

  log "Nach ${TL_INSTALL_DIR} verschieben"
  mkdir -p "$(dirname "${TL_INSTALL_DIR}")"
  mv "${SRC_DIR}" "${TL_INSTALL_DIR}"
fi

log "Besitzrechte auf www-data setzen"
chown -R www-data:www-data "${TL_INSTALL_DIR}"

log "Apache-VirtualHost anlegen (${TL_DOMAIN}:${TL_HTTP_PORT})"
if [[ "${TL_HTTP_PORT}" != "80" ]] && ! grep -q "^Listen ${TL_HTTP_PORT}\$" /etc/apache2/ports.conf; then
  echo "Listen ${TL_HTTP_PORT}" >> /etc/apache2/ports.conf
fi

VHOST_FILE="/etc/apache2/sites-available/testlink.conf"
cat > "${VHOST_FILE}" <<EOF
<VirtualHost *:${TL_HTTP_PORT}>
    ServerName ${TL_DOMAIN}
    DocumentRoot ${TL_INSTALL_DIR}

    <Directory ${TL_INSTALL_DIR}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/testlink-error.log
    CustomLog \${APACHE_LOG_DIR}/testlink-access.log combined
</VirtualHost>
EOF

a2ensite testlink.conf >/dev/null
systemctl reload apache2

log "Fertig. TestLink liegt unter ${TL_INSTALL_DIR}, erreichbar unter http://${TL_DOMAIN}:${TL_HTTP_PORT}/"
echo "Naechster Schritt: docs/installation/07-web-installer.md (Browser auf http://${TL_DOMAIN}:${TL_HTTP_PORT}/install/ oeffnen)"
