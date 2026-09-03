# 2 – Backup & Restore im laufenden Betrieb

## Ziel dieses Kapitels

Ein wiederholbares, geplantes Backup der **laufenden** TestLink-Instanz einrichten — nicht die einmalige
Sicherung vor der Migration ([`migration/04`](../migration/04-vollstaendigkeit-produktivmigration.md)),
sondern das, was ab jetzt regelmäßig laufen muss, solange TestLink produktiv genutzt wird.

## Warum das eine andere Aufgabe ist als die Migrations-Sicherung

Bei der Migration hast du **einmalig** einen Dump gezogen, bevor du etwas verändert hast — ein
Sicherheitsnetz für einen einzelnen, riskanten Moment. Im laufenden Betrieb ändern sich die Daten aber
**ständig** (neue Testfälle, Testläufe, Anhänge) — ein einmaliges Backup von vor drei Monaten hilft dir
nicht, wenn heute jemand aus Versehen ein ganzes Test-Projekt löscht. Du brauchst also einen
**wiederkehrenden, automatisierten** Prozess.

## Was gesichert werden muss (Erinnerung aus Migrations-Kapitel 4)

Genau dieselben zwei Kategorien wie bei der Migration:

1. **Die PostgreSQL-Datenbank** — alle Tabellendaten.
2. **`upload_area/`** — Datei-Anhänge, **falls** deine Instanz im Dateisystem-Modus läuft (prüfe wie in
   [Migrations-Kapitel 4](../migration/04-vollstaendigkeit-produktivmigration.md#kritischer-punkt-wo-liegen-die-anhänge-wirklich)
   beschrieben). Ein Backup, das nur die Datenbank sichert, aber nicht die Anhänge, ist bei
   Dateisystem-Modus unvollständig — Testfälle wären nach einer Wiederherstellung da, ihre Anhänge nicht.

## Schritt 1: Backup-Skript nutzen

Dieses Repo bringt ein fertiges Skript dafür mit:

```bash
export PGPASSWORD='DeinPostgresPasswort'
./scripts/backup-postgres.sh
```

Es sichert Datenbank **und** `upload_area/` (falls vorhanden) mit Zeitstempel nach
`/var/backups/testlink-postgres/` und löscht automatisch Backups, die älter als 14 Tage sind
(einstellbar über `KEEP_DAYS`). Die Zugangsdaten kommen bewusst aus einer Umgebungsvariable, nicht als
Kommandozeilen-Argument — sonst würden sie in der Shell-History landen.

## Schritt 2: Automatisieren statt merken

Ein Backup, an das du dich von Hand erinnern musst, wird irgendwann vergessen. Zwei gängige Wege, es
automatisch laufen zu lassen:

**Cron** (einfach, auf jedem Linux-System verfügbar):

```bash
sudo crontab -e
```

Zeile ergänzen, die das Skript täglich um 2 Uhr nachts ausführt:

```
0 2 * * * PGPASSWORD='DeinPostgresPasswort' /pfad/zu/scripts/backup-postgres.sh >> /var/log/testlink-backup.log 2>&1
```

**systemd-Timer** (moderner, bessere Log-Integration über `journalctl`) — falls du das aus deinem
Linux-Lernpfad schon kennst, ist das die robustere Alternative zu Cron; für den Einstieg reicht Cron
völlig aus.

## Schritt 3: Restore testen — der Schritt, den die meisten auslassen

Ein Backup, das du nie zurückgespielt hast, ist eine unbestätigte Vermutung, kein verlässliches Backup.
Teste das **regelmäßig**, nicht nur einmal:

```bash
# Datenbank in eine NEUE, separate Test-Datenbank einspielen (niemals direkt in die produktive!)
gunzip -c /var/backups/testlink-postgres/db_2026-09-01_02-00-00.sql.gz \
  | psql -h 127.0.0.1 -U postgres -d testlink_restore_test

# Stichprobe: ein paar Zeilen vergleichen
psql -h 127.0.0.1 -U postgres -d testlink_restore_test -c "SELECT COUNT(*) FROM users;"
```

Wenn das ohne Fehler durchläuft und die Zahlen plausibel sind, funktioniert dein Backup wirklich — nicht
nur theoretisch.

## Faustregel für Aufbewahrung

Es gibt keine universell richtige Antwort, aber eine gängige, einfache Regel für den Einstieg:

- **Täglich** für die letzten 14 Tage (deckt "ich habe gestern/vorgestern etwas kaputt gemacht" ab)
- **Wöchentlich** für die letzten 2–3 Monate (deckt "das ist seit einer Weile falsch, aber erst jetzt
  aufgefallen" ab)

Das Skript deckt aktuell nur die tägliche Rotation ab (`KEEP_DAYS`) — für eine feinere Staffelung
müsstest du es erweitern oder wöchentliche Backups in ein separates Verzeichnis mit eigener
Aufbewahrungsfrist legen.

## Was du gelernt hast

- Migrations-Backup (einmalig, vor einer riskanten Aktion) und Betriebs-Backup (wiederkehrend) sind
  unterschiedliche Aufgaben mit unterschiedlichen Anforderungen.
- Ein vollständiges TestLink-Backup umfasst Datenbank **und** ggf. `upload_area/`.
- Automatisierung (Cron/systemd-Timer) ist kein "nice to have" — ein manuell erinnerbares Backup wird
  irgendwann vergessen.
- Ein ungetestetes Backup ist keine verlässliche Absicherung — regelmäßiges Zurückspielen in eine
  separate Testumgebung gehört dazu.

## Verständnis-Check

1. Warum reicht das einmalige Migrations-Backup aus `migration/04` nicht für den laufenden Betrieb?
2. Was fehlt in deinem Backup, wenn du nur die PostgreSQL-Datenbank sicherst, aber TestLink im
   Dateisystem-Modus für Anhänge läuft?
3. Warum spielst du ein Test-Backup in eine **separate** Datenbank ein statt direkt in die produktive?

Weiter mit [Kapitel 3: Performance & Monitoring](03-performance-monitoring.md).
