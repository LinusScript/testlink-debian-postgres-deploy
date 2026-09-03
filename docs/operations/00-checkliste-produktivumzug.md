# 0 – Checkliste: Produktivumzug

Eine einzige, abhakbare Liste für den echten Migrationstermin — konsolidiert aus
[`installation/`](../installation/README.md), [`migration/`](../migration/README.md) und diesem Ordner.
Jeder Punkt verlinkt zur ausführlichen Erklärung; hier steht bewusst nur das Nötigste zum Abhaken, nicht
noch einmal der Hintergrund.

## Vorbereitung (Tage vorher)

- [ ] Von Kollegen geklärt: aktuelle TestLink-Version, DB-Engine/Version in Prod (siehe
      [Migrations-Kapitel 1](../migration/01-konzept.md))
- [ ] Geklärt: Speichert Prod Anhänge in DB oder Dateisystem? (`$g_repositoryType`, siehe
      [Migrations-Kapitel 4](../migration/04-vollstaendigkeit-produktivmigration.md))
- [ ] Zeichensatz der Produktivdatenbank geprüft (`SHOW CREATE TABLE ...`)
- [ ] Zielumgebung (Debian + Apache + PHP + PostgreSQL + aktuelle TestLink-Version) auf einer separaten
      VM fertig aufgesetzt und getestet — [`installation/`](../installation/README.md)
- [ ] Kompletter Migrationsweg (App-Upgrade + DB-Wechsel) mindestens einmal mit Testdaten auf der
      Demo-VM erfolgreich durchgespielt — [`migration/`](../migration/README.md)
- [ ] Wartungsfenster mit dem Team abgestimmt, Downtime angekündigt

## Am Migrationstermin

- [ ] Frischer `mysqldump` der Produktionsdatenbank gezogen (Rollback-Basis) — sicher übertragen,
      Zugriffsrechte `600` (siehe [Migrations-Kapitel 4](../migration/04-vollstaendigkeit-produktivmigration.md))
- [ ] `upload_area/` per `rsync` übertragen, falls Dateisystem-Modus
- [ ] App-Upgrade auf MySQL durchgeführt (Ausgangslage → Zielversion) —
      [Migrations-Kapitel 2](../migration/02-schritt1-app-upgrade.md)
- [ ] `pgloader`-Migration MySQL → PostgreSQL durchgeführt —
      [Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md)
- [ ] `./scripts/compare-migration-rowcounts.sh` — alle Tabellen stimmen überein
- [ ] Stichproben geprüft: Anhang öffnen, Testfall-Historie, Nicht-Admin-Login, Sonderzeichen/Umlaute
- [ ] `custom_config.inc.php` gezielt übertragen (nicht blind kopiert)

## Direkt danach

- [ ] Installer-Verzeichnis gesperrt — `scripts/99-lock-installer.sh` (siehe
      [`installation/09`](../installation/09-hardening-and-prod.md))
- [ ] Schreibrechte eingeschränkt, `config_db.inc.php` auf `640` gesetzt
- [ ] HTTPS/Zertifikat eingerichtet (echte Domain vorausgesetzt)
- [ ] Erstes reguläres Backup mit `scripts/backup-postgres.sh` gezogen und **Restore getestet** (siehe
      [Kapitel 2](02-backup-restore.md))
- [ ] Backup-Automatisierung (Cron/Timer) eingerichtet
- [ ] Team informiert: Wartungsfenster beendet, TestLink wieder verfügbar

## In den ersten Tagen danach

- [ ] Performance-Kennzahlen einmal bewusst geprüft (Festplatte, DB-Verbindungen, Apache-Worker) —
      [Kapitel 3](03-performance-monitoring.md), als Referenzwert für später
- [ ] Alte MySQL-Instanz **noch nicht löschen** — als Fallback behalten, bis sich das Team einig ist,
      dass alles stimmt (mindestens ein paar Wochen produktiven Betrieb abwarten)
- [ ] Kollegen die Benutzerverwaltung erklärt bzw. dieses Repo als Referenz gezeigt —
      [Kapitel 1](01-user-management.md)

## Falls etwas schiefgeht

Die alte MySQL-Datenbank ist zu diesem Zeitpunkt **unverändert** (siehe
[Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md) — `pgloader` liest nur) — der einfachste
Rollback ist, den DNS/VirtualHost wieder auf die alte Instanz zeigen zu lassen, während du in Ruhe
analysierst, was bei der neuen Instanz nicht stimmte, und es auf der Demo-VM nachstellst statt live zu
debuggen.
