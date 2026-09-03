# Was ist PostgreSQL?

## Kurzfassung

PostgreSQL ist ein **relationales Datenbank-Managementsystem** (RDBMS) — die Software, die unsere
Daten (Testfälle, Projekte, Benutzer, ...) strukturiert, dauerhaft und konsistent speichert. In unserem
Stack ist es die **Ziel-Datenbank**, zu der wir von MySQL/MariaDB migrieren.

## Geschichte

PostgreSQL geht auf das Forschungsprojekt **POSTGRES** zurück, das 1986 an der University of California,
Berkeley, unter Leitung von **Professor Michael Stonebraker** begann — als Nachfolger seines
erfolgreichen früheren Datenbankprojekts "Ingres", diesmal mit Fokus auf **Erweiterbarkeit** (der Name
POSTGRES bedeutet wörtlich "post-Ingres", also "nach Ingres"). 1994 fügten Andrew Yu und Jolly Chen dem
Projekt einen SQL-Sprachinterpreter hinzu — vorher unterstützte es eine andere Abfragesprache. 1996 kam
mit dem SQL-Support auch der heutige Name: **PostgreSQL**. Seitdem wird es von einer weltweiten
Open-Source-Community weiterentwickelt (nicht von einem einzelnen Unternehmen kontrolliert).

**Warum das für dich relevant ist:** Der Erweiterbarkeits-Fokus aus der Forschungsgeschichte ist bis
heute PostgreSQLs Markenzeichen — es unterstützt sehr strikt den SQL-Standard, eigene Datentypen,
komplexe Abfragen und gilt allgemein als besonders **korrekt und konsistent** in seinem Verhalten. Genau
diese Strenge ist auch der Grund, warum eine MySQL-Datenbank nicht einfach "umkonfiguriert" werden kann
(siehe [Kapitel 10](../tutorial/10-migrationskonzept.md)) — PostgreSQL interpretiert SQL an mehreren
Stellen bewusst anders/strenger als MySQL.

## Kernkonzept: Relationale Datenspeicherung

"Relational" bedeutet: Daten liegen in **Tabellen** mit fest definierten Spalten (Struktur/Schema), und
Beziehungen zwischen Tabellen werden über **Fremdschlüssel** abgebildet, statt Daten mehrfach zu
duplizieren. Beispiel aus TestLink: Ein Testfall (Tabelle `tcversions`) referenziert seinen Platz im
Baum (Tabelle `nodes_hierarchy`) über eine ID, statt den gesamten Pfad bei jedem Testfall neu zu
speichern.

PostgreSQL kennt außerdem statt "Benutzer" und "Gruppen" nur ein einheitliches Konzept: **Rollen**
(`ROLE`) — eine Rolle kann sich einloggen (dann faktisch ein Benutzer) und/oder andere Rollen enthalten
(dann faktisch eine Gruppe). Details dazu in [Kapitel 4](../tutorial/04-postgresql.md).

## Wofür wird es verwendet

Allgemein: als Standard-Datenbank für sehr viele moderne Web-Anwendungen, oft bevorzugt gegenüber MySQL,
wenn hohe Datenkonsistenz, komplexe Abfragen oder Erweiterbarkeit (z. B. Geodaten mit PostGIS) gefragt
sind.

In unserem Kontext: PostgreSQL speichert nach der Migration alle TestLink-Daten — Projekte, Testfälle,
Testläufe, Benutzer, Rechte.

## Wichtige Begriffe

- **Rolle (Role)** — PostgreSQLs einheitliches Konzept für Benutzer und Gruppen.
- **Superuser** — die Rolle `postgres`, darf alles (Datenbanken anlegen, andere Rollen verwalten).
- **`pg_hba.conf`** — die zentrale Zugriffssteuerungsdatei: wer darf sich von wo aus wie anmelden
  (siehe [Kapitel 4](../tutorial/04-postgresql.md)).
- **Sequenz** — PostgreSQLs Mechanismus für automatisch hochzählende ID-Spalten (das Gegenstück zu
  MySQLs `AUTO_INCREMENT`, siehe [Kapitel 10](../tutorial/10-migrationskonzept.md)).
- **Schema** — ein Namensraum *innerhalb* einer Datenbank (Standard: `public`) — nicht zu verwechseln
  mit "Datenbank-Schema" im allgemeinen Sinn (Tabellenstruktur).
- **`psql`** — das Kommandozeilen-Werkzeug, um mit PostgreSQL zu interagieren.

## Die wichtigsten Befehle

```bash
psql -h 127.0.0.1 -U postgres          # per TCP mit Passwort verbinden
sudo -u postgres psql                   # lokal über den Unix-Socket verbinden (peer-Auth, kein Passwort)
```

Innerhalb von `psql` — Metabefehle beginnen mit `\` und werden von `psql` selbst interpretiert, nicht
als SQL an den Server geschickt:

```
\l          Alle Datenbanken auflisten
\du         Alle Rollen (Benutzer) auflisten
\c dbname   Zu einer anderen Datenbank wechseln
\dt         Alle Tabellen der aktuellen Datenbank auflisten
\conninfo   Zeigt, mit welcher Datenbank/als wer du gerade verbunden bist
\q          psql verlassen
```

Auf der Kommandozeile (außerhalb von `psql`):

```bash
sudo -u postgres createdb <name>        # neue, leere Datenbank anlegen
pg_dump <db> > backup.sql                # Datenbank in eine SQL-Datei exportieren
psql <db> < backup.sql                    # SQL-Datei in eine Datenbank einspielen
```

## Bezug zu unserem Projekt

- [Kapitel 4](../tutorial/04-postgresql.md) — Installation, Rollen, `pg_hba.conf` Zeile für Zeile
- [Kapitel 7](../tutorial/07-web-installer.md) — wie TestLink seine PostgreSQL-Datenbank selbst anlegt
- [Kapitel 12](../tutorial/12-migration-schritt2-db-wechsel.md) — die eigentliche Migration von MySQL
