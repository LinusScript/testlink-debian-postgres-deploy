#!/usr/bin/env bash
# Vergleicht die Zeilenzahl JEDER Tabelle zwischen der MySQL-Quelle und der
# migrierten PostgreSQL-Zieldatenbank nach einer TestLink-Migration.
# Hintergrund und Nutzung: docs/migration/04-vollstaendigkeit-produktivmigration.md
#
# Zugangsdaten NICHT als Argument uebergeben (landet in Shell-History/Prozessliste),
# sondern vorher exportieren:
#   export MYSQL_PWD='...'
#   export PGPASSWORD='...'
#   ./scripts/compare-migration-rowcounts.sh
set -euo pipefail

MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_DB="${MYSQL_DB:-testlink}"
MYSQL_USER="${MYSQL_USER:-tl_login}"

PG_HOST="${PG_HOST:-127.0.0.1}"
PG_DB="${PG_DB:-testlink_migrated}"
PG_USER="${PG_USER:-postgres}"

: "${MYSQL_PWD:?Bitte vorher exportieren: export MYSQL_PWD='...'}"
: "${PGPASSWORD:?Bitte vorher exportieren: export PGPASSWORD='...'}"

echo "Ermittle Tabellenliste aus MySQL-Datenbank '${MYSQL_DB}' ..."
TABLES=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -N -B -e \
  "SELECT table_name FROM information_schema.tables WHERE table_schema='${MYSQL_DB}';" "$MYSQL_DB")

printf "%-40s %12s %12s %12s\n" "Tabelle" "MySQL" "PostgreSQL" "Status"
printf '%.0s-' {1..78}; echo

MISMATCH=0
for T in $TABLES; do
  MYSQL_COUNT=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -N -B -e "SELECT COUNT(*) FROM \`${T}\`;" "$MYSQL_DB")
  PG_COUNT=$(psql -h "$PG_HOST" -U "$PG_USER" -d "$PG_DB" -tAc "SELECT COUNT(*) FROM \"${T}\";" 2>/dev/null | tr -d '[:space:]')
  [[ -z "$PG_COUNT" ]] && PG_COUNT="FEHLT"

  STATUS="OK"
  if [[ "$MYSQL_COUNT" != "$PG_COUNT" ]]; then
    STATUS="ABWEICHUNG"
    MISMATCH=1
  fi
  printf "%-40s %12s %12s %12s\n" "$T" "$MYSQL_COUNT" "$PG_COUNT" "$STATUS"
done

echo
if [[ "$MISMATCH" -eq 1 ]]; then
  echo "WARNUNG: Mindestens eine Tabelle weicht in der Zeilenzahl ab - siehe oben."
  exit 1
fi
echo "Alle Tabellen stimmen in der Zeilenzahl ueberein."
