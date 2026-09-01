# 12 – Schritt 2: Von MySQL zu PostgreSQL migrieren

## Ziel dieses Kapitels

Die Daten aus der jetzt auf 1.9.20 aktualisierten MySQL-Datenbank (Kapitel 11) nach PostgreSQL
übertragen — Schema **und** Inhalte — sodass am Ende dieselbe TestLink-Instanz auf der
PostgreSQL-Umgebung aus [Kapitel 3–7](03-php.md) läuft.

## Warum reicht "TestLink neu installieren und Daten von Hand eintippen" nicht?

Bei einer Demo mit ein paar Testfällen vielleicht — aber die Produktivinstanz enthält vermutlich echte
Projekte, Testfälle mit Historie, Testläufe, Benutzer mit Rechten, ggf. Anhänge. Das von Hand zu
übertragen ist bei realistischen Datenmengen weder praktikabel noch fehlerfrei. Wir brauchen ein
Werkzeug, das **Schema und Daten automatisiert überträgt** und dabei die Typunterschiede aus
[Kapitel 10](10-migrationskonzept.md) korrekt behandelt.

## Was macht `pgloader`, und warum genau das?

[`pgloader`](https://pgloader.io/) ist ein spezialisiertes Werkzeug für genau diesen Fall: Es verbindet
sich mit einer MySQL-Quelle, liest deren Schema **und** Daten, erzeugt daraus automatisch ein passendes
PostgreSQL-Schema (inklusive der Typ-Übersetzungen aus Kapitel 10 — `AUTO_INCREMENT` → Sequenz,
`TINYINT(1)` → `BOOLEAN`, Zeichensatz-Konvertierung) und kopiert die Daten in einem Rutsch. Am Ende
liefert es einen Bericht: wie viele Zeilen pro Tabelle migriert wurden, und ob es Warnungen/Fehler gab.

Das ist der Grund, warum wir in [Kapitel 11](11-migration-schritt1-app-upgrade.md) zuerst die
App-Version aktualisiert haben: `pgloader` migriert 1:1, was in der Quelle vorhanden ist — wenn die
Quelle bereits auf 1.9.20-Schema-Stand ist, landet automatisch auch das 1.9.20-Schema in PostgreSQL,
passend zu dem, was TestLink 1.9.20-20251208 erwartet.

## Schritt 1: `pgloader` installieren

```bash
sudo apt-get update
sudo apt-get install -y pgloader
```

## Schritt 2: Leere Zieldatenbank in PostgreSQL anlegen

Wichtig: **nicht** über den TestLink-Web-Installer (der würde ein leeres 1.9.20-Postgres-Schema selbst
erzeugen — wir wollen aber, dass `pgloader` das Schema erzeugt, exakt abgeleitet aus der MySQL-Quelle).
Stattdessen legst du nur eine **leere** Datenbank an, mit dem PostgreSQL-Superuser aus
[Kapitel 4](04-postgresql.md):

```bash
sudo -u postgres createdb testlink_migrated
```

## Schritt 3: pgloader-Kommandodatei schreiben

`pgloader` wird über eine Kommandodatei gesteuert (Endung `.load`), die Quelle, Ziel und Optionen
beschreibt:

```bash
nano migrate-testlink.load
```

Inhalt:

```
LOAD DATABASE
    FROM mysql://tl_login:DeinStarkesPasswort123!@localhost/testlink
    INTO postgresql://postgres:DeinPgSuperuserPasswort@localhost/testlink_migrated

WITH include drop, create tables, create indexes, reset sequences,
     downcase identifiers

SET work_mem to '16MB', maintenance_work_mem to '512MB';
```

Kurz erklärt:

- `FROM` / `INTO` — Quelle (MySQL) und Ziel (PostgreSQL) als Verbindungs-URLs, genau wie du sie schon
  aus `config_db.inc.php`-Werten kennst, nur in URL-Form zusammengeschrieben.
- `include drop, create tables, create indexes` — falls die Zieldatenbank schon Tabellen enthält (z. B.
  bei einem zweiten Testlauf), werden sie vorher verworfen und sauber neu angelegt — praktisch für
  wiederholte Testläufe auf der Demo-VM.
- `reset sequences` — nach dem Kopieren der Daten die PostgreSQL-Sequenzen (der Ersatz für
  `AUTO_INCREMENT`, siehe Kapitel 10) auf den nächsten freien Wert setzen, damit neue Datensätze nach
  der Migration nicht mit vorhandenen IDs kollidieren.
- `downcase identifiers` — Tabellen-/Spaltennamen in Kleinschreibung, PostgreSQLs Konvention (TestLinks
  eigenes `install/sql/postgres/`-Schema verwendet ebenfalls durchgängig Kleinschreibung).

## Schritt 4: Migration ausführen

```bash
pgloader migrate-testlink.load
```

Das dauert je nach Datenmenge einige Sekunden bis Minuten. Am Ende zeigt `pgloader` eine Tabelle mit
Zeilenanzahl pro migrierter Tabelle sowie etwaigen Warnungen — **lies sie**, statt nur auf "kein
Absturz" zu vertrauen.

## Schritt 5: Stichproben-Vergleich zwischen Quelle und Ziel

Bevor du der Migration traust, vergleiche konkrete Zahlen zwischen beiden Datenbanken:

```bash
# MySQL-Seite (Quelle)
mysql -u tl_login -p testlink -e "SELECT COUNT(*) FROM users;"
mysql -u tl_login -p testlink -e "SELECT COUNT(*) FROM nodes_hierarchy;"

# PostgreSQL-Seite (Ziel)
psql -h 127.0.0.1 -U postgres -d testlink_migrated -c "SELECT COUNT(*) FROM users;"
psql -h 127.0.0.1 -U postgres -d testlink_migrated -c "SELECT COUNT(*) FROM nodes_hierarchy;"
```

`nodes_hierarchy` ist TestLinks zentrale Baumstruktur-Tabelle (Test-Suites, Testfälle, Requirements
hängen alle darin) — eine gute Tabelle für einen schnellen Sanity-Check, weil sie bei jedem
nicht-trivialen Projekt viele Zeilen hat.

## Schritt 6: TestLink auf die neue PostgreSQL-Datenbank umstellen

`pgloader` verbindet sich meist mit Superuser-Rechten — für den laufenden Betrieb willst du (wie in
Kapitel 7 gelernt) einen eingeschränkten Nutzer, nicht den Superuser:

```bash
sudo -u postgres psql -d testlink_migrated -c "
  CREATE USER tl_login_pg WITH PASSWORD 'NochEinStarkesPasswort!';
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tl_login_pg;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tl_login_pg;
"
```

Danach `config_db.inc.php` deiner TestLink-Instanz (dieselbe Codebasis, mit der du in Kapitel 11 schon
gegen MySQL gearbeitet hast) auf PostgreSQL umstellen:

```php
<?php
$tlCfg->db_type = 'postgres';
$tlCfg->db_host = 'localhost';
$tlCfg->db_name = 'testlink_migrated';
$tlCfg->db_user = 'tl_login_pg';
$tlCfg->db_pass = 'NochEinStarkesPasswort!';
```

## Schritt 7: Im Browser prüfen

TestLink im Browser aufrufen, einloggen, ein paar Projekte/Testfälle stichprobenartig durchklicken —
insbesondere solche mit Anhängen oder Sonderzeichen (Umlaute!), weil dort Zeichensatz-Probleme bei
Datenbank-Migrationen am ehesten sichtbar werden.

## Zur Sicherheit: Die MySQL-Datenbank bleibt unangetastet

`pgloader` **liest nur** aus MySQL, es verändert die Quelle nicht. Das heißt: Wenn in PostgreSQL etwas
nicht stimmt, kannst du `testlink_migrated` löschen und die Migration beliebig oft wiederholen, ohne
Datenverlust an der Quelle zu riskieren — derselbe Backup-Gedanke wie in
[Kapitel 9](09-hardening-and-prod.md) gilt auch hier für den echten Migrationstermin: Vor dem echten
Umzug einen frischen MySQL-Dump als Fallback sichern, dann erst migrieren.

## Was du gelernt hast

- `pgloader` überträgt Schema und Daten automatisiert zwischen unterschiedlichen Datenbanksystemen und
  löst dabei die Typunterschiede aus Kapitel 10 auf.
- Weil Schritt 1 zuerst die App-Version aktualisiert hat, migriert `pgloader` in Schritt 2 direkt in ein
  bekanntes, korrektes Ziel-Schema.
- Ein Migrationstool, das nur liest statt die Quelle zu verändern, macht wiederholte Testläufe risikofrei.
- Zahlenvergleiche (Zeilenanzahl) sind eine schnelle, konkrete Methode, einer Migration zu vertrauen —
  besser als "sieht auf den ersten Blick gut aus".

## Verständnis-Check

1. Warum bringt `pgloader` das Datenbankschema selbst mit, statt dass du es vorher manuell in PostgreSQL
   anlegst?
2. Was bedeutet `reset sequences`, und warum ist das nach einer MySQL→PostgreSQL-Migration nötig?
3. Warum ist es unkritisch, die Migration bei einem Fehler einfach zu wiederholen?
4. Was würdest du unmittelbar vor dem echten Produktiv-Migrationstermin zusätzlich tun, das hier auf der
   Demo-VM nicht nötig war?

## Von der Demo zur echten Migration

Diese beiden Kapitel haben dir den kompletten Weg gezeigt — mit synthetischen 1.9.16-Standarddaten statt
echten Produktivdaten. Für den echten Umzug ändert sich am **Ablauf** nichts, nur an den Eingaben:

- Statt `testlink_create_default_data.sql` verwendest du einen echten Dump der Produktions-MySQL-Datenbank
  (von deinem Kollegen, siehe die Nachricht, die du ihm geschickt hast).
- Du brauchst ein abgestimmtes **Wartungsfenster** (Downtime), weil während der Migration niemand mehr in
  TestLink arbeiten darf.
- Ein frischer MySQL-Dump unmittelbar vor der Migration ist dein Rollback-Plan, falls etwas schiefgeht.
- Führe **exakt diese Schritte in derselben Reihenfolge** aus, die du hier bereits erfolgreich getestet
  hast — das ist der ganze Sinn dieses Repos.
