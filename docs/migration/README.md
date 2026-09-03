# Migration: TestLink 1.9.16/MySQL → PostgreSQL

Dieser Teil des Repos ist kein weiteres Installations-Kapitel, sondern die **eigentliche Aufgabe**, für
die die [Installation](../installation/README.md) die Zielumgebung vorbereitet hat: Produktion läuft
aktuell auf **TestLink 1.9.16 mit MySQL/MariaDB**, das Ziel ist die aktuelle TestLink-Version auf
**PostgreSQL**.

## Voraussetzung

Du hast die [Installation](../installation/README.md) (Kapitel 0–9) bereits durchgearbeitet — die
Demo-VM hat also schon eine funktionierende Apache/PHP/PostgreSQL-Umgebung mit der Ziel-TestLink-Version.
Diese Kapitel hier setzen genau darauf auf und ergänzen MySQL/MariaDB als zweite Datenbank auf derselben
VM, um den echten Migrationsweg nachzubilden und zu testen.

## Kapitel

| # | Kapitel | Worum es geht |
|---|---|---|
| 1 | [Migrationskonzept](01-konzept.md) | Warum App-Version-Update und DB-Engine-Wechsel getrennte Probleme sind — mit Belegen aus dem TestLink-Quellcode |
| 2 | [Schritt 1: App-Upgrade](02-schritt1-app-upgrade.md) | TestLink 1.9.16 → 1.9.20 manuell per SQL, MySQL bleibt MySQL |
| 3 | [Schritt 2: DB-Wechsel](03-schritt2-db-wechsel.md) | MySQL → PostgreSQL mit `pgloader`, gleiche TestLink-Version |
| 4 | [Vollständigkeits-Check](04-vollstaendigkeit-produktivmigration.md) | Anhänge im Dateisystem, echter Produktivdump, alle ~58 Tabellen verifizieren statt Stichproben |

## Warum diese Reihenfolge

Kapitel 1 erklärt es im Detail, kurz vorweg: App-Version-Update (Kapitel 2) und Datenbank-Engine-Wechsel
(Kapitel 3) werden bewusst **getrennt** behandelt und getestet, statt in einem Schritt kombiniert — bei
einem Fehler ist so sofort klar, welcher der beiden Schritte betroffen ist. Kapitel 4 überträgt den auf
der Demo-VM erprobten Weg schließlich auf echte Produktivdaten.

## Hintergrundwissen zu den Werkzeugen

Für die hier verwendeten Werkzeuge (MySQL/MariaDB, `pgloader`) gibt es jeweils eine eigene Seite unter
[`docs/grundlagen/`](../grundlagen/README.md) — was das Werkzeug ist, woher es kommt, wofür es gedacht
ist:

- [MySQL/MariaDB](../grundlagen/mariadb-mysql.md)
- [pgloader](../grundlagen/pgloader.md)
- [TestLink](../grundlagen/testlink.md) — für den fachlichen Hintergrund, *warum* diese Migration
  überhaupt stattfindet
