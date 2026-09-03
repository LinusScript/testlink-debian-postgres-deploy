#!/usr/bin/env bash
# Regelmaessiges Backup der laufenden TestLink-PostgreSQL-Datenbank (nach der Migration).
# Nicht zu verwechseln mit dem einmaligen Migrations-Sicherungsschritt in docs/migration/.
# Hintergrund und Nutzung: docs/operations/02-backup-restore.md
#
# Zugangsdaten NICHT als Argument uebergeben, vorher exportieren:
#   export PGPASSWORD='...'
#   ./scripts/backup-postgres.sh
set -euo pipefail

PG_HOST="${PG_HOST:-127.0.0.1}"
PG_PORT="${PG_PORT:-5432}"
PG_DB="${PG_DB:-testlink_migrated}"
PG_USER="${PG_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/testlink-postgres}"
KEEP_DAYS="${KEEP_DAYS:-14}"
UPLOAD_AREA="${UPLOAD_AREA:-/var/www/testlink/upload_area}"

: "${PGPASSWORD:?Bitte vorher exportieren: export PGPASSWORD='...'}"

mkdir -p "${BACKUP_DIR}"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

echo "Sichere Datenbank '${PG_DB}' ..."
pg_dump -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" "${PG_DB}" \
  | gzip > "${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
echo "OK: ${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz ($(du -h "${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz" | cut -f1))"

if [[ -d "${UPLOAD_AREA}" ]]; then
  echo "Sichere Datei-Anhaenge (${UPLOAD_AREA}) ..."
  tar -czf "${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz" -C "$(dirname "${UPLOAD_AREA}")" "$(basename "${UPLOAD_AREA}")"
  echo "OK: ${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz ($(du -h "${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz" | cut -f1))"
else
  echo "Kein upload_area unter ${UPLOAD_AREA} gefunden - ueberspringe (Datenbank-Modus? siehe docs/migration/04)."
fi

echo "Entferne Backups aelter als ${KEEP_DAYS} Tage ..."
find "${BACKUP_DIR}" -name "db_*.sql.gz" -mtime "+${KEEP_DAYS}" -delete
find "${BACKUP_DIR}" -name "uploads_*.tar.gz" -mtime "+${KEEP_DAYS}" -delete

echo "Fertig."
