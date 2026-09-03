# Was sind MySQL und MariaDB?

## Kurzfassung

MySQL ist ein weit verbreitetes relationales Datenbank-Managementsystem; **MariaDB** ist eine
Weiterentwicklung ("Fork") davon, die zu MySQL weitgehend kompatibel ist. In unserem Stack ist das die
Datenbank der **aktuellen Produktivumgebung** (TestLink 1.9.16), die wir Richtung PostgreSQL migrieren.

## Geschichte

MySQL wurde 1995 von **Michael "Monty" Widenius**, **David Axmark** und **Allan Larsson** entwickelt und
unter der Firma MySQL AB vertrieben — der Name kombiniert "SQL" mit "My", dem Namen von Montys Tochter.
MySQL wurde vor allem für seine **Einfachheit und Geschwindigkeit** bekannt und war über Jahre die
Standard-Datenbank für Web-Anwendungen (der Kern des klassischen "LAMP-Stacks": **L**inux, **A**pache,
**M**ySQL, **P**HP — genau die Kombination, die TestLink historisch voraussetzt).

2008 kaufte **Sun Microsystems** MySQL AB, 2010 wiederum übernahm **Oracle** Sun Microsystems — und
damit MySQL. Diese Entwicklung sorgte in der Open-Source-Community für Sorge um die Zukunft des freien
MySQL-Projekts. Noch bevor die Oracle-Übernahme offiziell abgeschlossen war, veröffentlichte Monty
Widenius im Oktober 2009 einen eigenen Fork: **MariaDB** — benannt nach seiner *anderen* Tochter Maria.
Ziel war, ein MySQL-kompatibles, aber garantiert offenes, community-getriebenes Projekt zu erhalten.
Debian (und damit auch unsere Demo-VM) liefert seit einigen Jahren standardmäßig MariaDB statt MySQL
aus, wenn man das generische `mysql-server`-Paket sucht.

**Warum das für dich relevant ist:** MariaDB ist praktisch ein direkter Ersatz für MySQL — dieselben
Kommandozeilenwerkzeuge (`mysql`, `mysqldump`), dieselbe SQL-Grunddialekt-Kompatibilität. Für unser
Projekt bedeutet das: Alles, was du über "MySQL" in TestLinks eigener Dokumentation liest, gilt praktisch
1:1 auch für unsere MariaDB-Installation.

## Kernkonzept

Wie PostgreSQL ist MySQL/MariaDB relational — Tabellen, Zeilen, Spalten, Fremdschlüssel. Der wichtigste
konzeptionelle Unterschied zu PostgreSQL, den du für die Migration verstehen musst (ausführlich in
[Kapitel 10](../tutorial/10-migrationskonzept.md)):

| | MySQL/MariaDB | PostgreSQL |
|---|---|---|
| Auto-increment | `AUTO_INCREMENT`-Attribut direkt an der Spalte | separates Sequenz-Objekt |
| Bezeichner-Anführung | `` `Backtick` `` | `"doppelte Anführungszeichen"` |
| Storage Engine | wählbar pro Tabelle (z. B. `InnoDB`) | kein vergleichbares Konzept |
| Nutzerverwaltung | direkt in der DB (`mysql.user`-Tabelle) | eigenes Rollen-System, plus `pg_hba.conf` |

## Wofür wird es verwendet

Allgemein: extrem verbreitet im Web-Bereich (WordPress, viele klassische PHP-Anwendungen), bekannt für
einfache Einrichtung und gute Performance bei klassischen Lese-lastigen Web-Workloads.

In unserem Kontext: MariaDB bildet die **Ausgangslage** nach — die TestLink-1.9.16-Produktivdatenbank,
die wir in [Kapitel 11](../tutorial/11-migration-schritt1-app-upgrade.md) zunächst app-seitig
aktualisieren, bevor wir in Kapitel 12 die Datenbank-Engine wechseln.

## Wichtige Begriffe

- **Storage Engine** — die Komponente, die tatsächlich festlegt, *wie* Daten auf der Platte liegen
  (Standard heute: `InnoDB`, mit Transaktionsunterstützung).
- **`mysql`-Client** — das Kommandozeilenwerkzeug für Abfragen und zum Einspielen von SQL-Dateien.
- **`mysqldump`** — Exportwerkzeug, erzeugt eine SQL-Datei mit Struktur + Daten einer Datenbank.
- **`unix_socket`-Authentifizierung** — MariaDBs Gegenstück zu PostgreSQLs `peer`-Auth: vertraut lokal
  dem angemeldeten Linux-Benutzer, ohne Passwort.
- **`information_schema`** — eine besondere, immer vorhandene Datenbank mit Metadaten über alle
  anderen Datenbanken (z. B. welche Tabellen existieren — nutzen wir in
  [Kapitel 13](../tutorial/13-vollstaendigkeit-produktivmigration.md)).

## Die wichtigsten Befehle

```bash
sudo mysql -u root                       # lokal verbinden (unix_socket-Auth, kein Passwort nötig)
mysql -u <user> -p <datenbank>            # per Passwort verbinden, gegen eine bestimmte DB

mysql -u <user> -p <db> < datei.sql        # SQL-Datei einspielen
mysql -u <user> -p <db> -e "SQL-BEFEHL;"    # einzelnen SQL-Befehl direkt ausführen (ohne interaktive Sitzung)

mysqldump --single-transaction -u <user> -p <db> > dump.sql   # konsistenten Export erzeugen
```

Innerhalb der `mysql`-Konsole (SQL, kein Metabefehl-System wie bei `psql`):

```sql
SHOW DATABASES;
USE testlink;
SHOW TABLES;
DESCRIBE attachments;
```

## Bezug zu unserem Projekt

- [Kapitel 11](../tutorial/11-migration-schritt1-app-upgrade.md) — MariaDB installieren, Ausgangslage
  nachbilden, Versions-Upgrade durchführen
- [Kapitel 13](../tutorial/13-vollstaendigkeit-produktivmigration.md) — einen echten Produktivdump
  korrekt exportieren
