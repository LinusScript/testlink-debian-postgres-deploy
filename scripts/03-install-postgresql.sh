#!/usr/bin/env bash
# Schritt 3: PostgreSQL installieren und fuer den TestLink-Web-Installer vorbereiten.
# Siehe docs/installation/04-postgresql.md
#
# WICHTIG: Legt bewusst KEINE TestLink-Datenbank/-User an - das macht der TestLink
# Web-Installer selbst (er verbindet sich als "postgres"-Superuser). Dieses Skript
# setzt nur das Superuser-Passwort und stellt sicher, dass Passwort-Login per TCP
# auf 127.0.0.1/::1 erlaubt ist.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib.sh

require_root
load_env

: "${PG_SUPERUSER_PASSWORD:?PG_SUPERUSER_PASSWORD muss in .env gesetzt sein}"

log "PostgreSQL installieren"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y postgresql postgresql-contrib

log "Passwort fuer PostgreSQL-Superuser 'postgres' setzen"
# Single Quotes im Passwort SQL-konform escapen (' -> '')
ESCAPED_PW="${PG_SUPERUSER_PASSWORD//\'/\'\'}"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER USER postgres WITH PASSWORD '${ESCAPED_PW}';"

log "PostgreSQL-Konfigurationsverzeichnis ermitteln"
PG_CONF_DIR="$(find /etc/postgresql -maxdepth 2 -type d -name main | sort -V | tail -n1)"
if [[ -z "${PG_CONF_DIR}" ]]; then
  echo "Konnte /etc/postgresql/<version>/main nicht finden." >&2
  exit 1
fi
echo "Verwende: ${PG_CONF_DIR}"

HBA_FILE="${PG_CONF_DIR}/pg_hba.conf"
CHANGED=0

log "pg_hba.conf auf TCP-Passwort-Login pruefen/ergaenzen"
if ! grep -Eq '^\s*host\s+all\s+all\s+127\.0\.0\.1/32\s+(scram-sha-256|md5)' "${HBA_FILE}"; then
  echo "host    all             all             127.0.0.1/32            scram-sha-256" >> "${HBA_FILE}"
  echo "Zeile fuer 127.0.0.1/32 ergaenzt."
  CHANGED=1
else
  echo "127.0.0.1/32 bereits erlaubt."
fi

if ! grep -Eq '^\s*host\s+all\s+all\s+::1/128\s+(scram-sha-256|md5)' "${HBA_FILE}"; then
  echo "host    all             all             ::1/128                 scram-sha-256" >> "${HBA_FILE}"
  echo "Zeile fuer ::1/128 ergaenzt."
  CHANGED=1
else
  echo "::1/128 bereits erlaubt."
fi

log "listen_addresses pruefen (informativ)"
CURRENT_LISTEN="$(sudo -u postgres psql -tAc "SHOW listen_addresses;" | tr -d '[:space:]')"
echo "Aktueller Wert: listen_addresses = '${CURRENT_LISTEN}'"
if [[ "${CURRENT_LISTEN}" != "localhost" && "${CURRENT_LISTEN}" != "*" ]]; then
  echo "WARNUNG: listen_addresses erlaubt evtl. kein TCP auf 127.0.0.1." >&2
  echo "Pruefe ${PG_CONF_DIR}/postgresql.conf manuell (siehe docs/installation/08-verification-debugging.md)." >&2
fi

if [[ "${CHANGED}" -eq 1 ]]; then
  log "PostgreSQL neu starten (pg_hba.conf geaendert)"
  systemctl restart postgresql
else
  log "PostgreSQL neu laden"
  systemctl reload postgresql
fi
systemctl enable postgresql >/dev/null

log "Verbindungstest per TCP mit Passwort"
if PGPASSWORD="${PG_SUPERUSER_PASSWORD}" psql -h "${PG_HOST:-127.0.0.1}" -U postgres -c '\conninfo' >/dev/null; then
  echo "OK: TCP-Verbindung mit Passwort erfolgreich."
else
  echo "FEHLER: TCP-Verbindung fehlgeschlagen - siehe docs/installation/08-verification-debugging.md" >&2
  exit 1
fi
