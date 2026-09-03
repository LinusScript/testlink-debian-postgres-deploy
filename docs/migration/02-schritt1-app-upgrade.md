# 2 – Schritt 1: TestLink 1.9.16 auf MySQL/MariaDB aktualisieren

## Ziel dieses Kapitels

Auf der Demo-VM eine MySQL-Datenbank mit **exakt dem Schema-Stand von TestLink 1.9.16** erzeugen (die
Produktions-Ausgangslage nachbilden) und sie mit den offiziellen SQL-Dateien manuell auf den Stand von
1.9.20 heben — ganz ohne PostgreSQL, das kommt erst in [Migrations-Kapitel 3](03-schritt2-db-wechsel.md).

## Warum brauchen wir jetzt zusätzlich MySQL auf der Demo-VM?

Wir haben in [Kapitel 3](../installation/03-php.md) und [Kapitel 4](../installation/04-postgresql.md) bewusst PostgreSQL gewählt — das
bleibt unser **Ziel**. Um den echten Migrationsweg zu proben, müssen wir aber zuerst die **Ausgangslage**
nachbilden, und die ist nun mal MySQL/MariaDB. Beide Datenbanken können auf derselben Demo-VM parallel
laufen (unterschiedliche Ports: MySQL/MariaDB standardmäßig 3306, PostgreSQL 5432) — das ist auf einer
Demo-VM unproblematisch, in Produktion würde man das trennen.

## MariaDB statt MySQL — warum, und was ändert sich?

Debian liefert standardmäßig **MariaDB** statt MySQL aus — ein Fork von MySQL, der zu über 99% derselben
SQL-Syntax und denselben Client-Werkzeugen (`mysql`-Kommando funktioniert unverändert) folgt. Für unseren
Zweck ist das identisch zu "echtem" MySQL. Die Konzepte aus Kapitel 4 (Rollen/Nutzer, Client-Authentifizierung)
gelten hier im Grundsatz genauso, nur mit anderen Befehlen — MySQL/MariaDB kennt kein `pg_hba.conf`,
sondern verwaltet Nutzerrechte direkt in der Datenbank selbst (Tabelle `mysql.user`).

## Schritt 1: MariaDB installieren

```bash
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
sudo systemctl status mariadb
```

## Schritt 2: Datenbank und Nutzer anlegen

Anders als bei PostgreSQL (wo der TestLink-Web-Installer das selbst erledigt, siehe Kapitel 7) legen wir
hier die Datenbank **manuell** an — wir wollen bewusst **nicht** über den Web-Installer "New Installation"
gehen, sondern direkt die 1.9.16-Schema-Dateien einspielen, um die reale Ausgangslage nachzubilden:

```bash
sudo mysql -u root
```

Innerhalb der `mysql`-Konsole:

```sql
CREATE DATABASE testlink CHARACTER SET utf8mb4;
CREATE USER 'tl_login'@'localhost' IDENTIFIED BY 'DeinStarkesPasswort123!';
GRANT ALL PRIVILEGES ON testlink.* TO 'tl_login'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

`sudo mysql -u root` funktioniert ohne Passwort, weil MariaDB auf Debian standardmäßig `unix_socket`-
Authentifizierung für `root` nutzt — das lokale Gegenstück zu PostgreSQLs `peer`-Auth aus Kapitel 4.

## Schritt 3: TestLink-1.9.16-Schema einspielen

Die beiden SQL-Dateien, die die 1.9.16-Datenbankstruktur **und** die TestLink-Standarddaten (Rollen,
Rechte-Definitionen, Default-Konfiguration) erzeugen, liegen im damaligen Tag `1.9.16`:

```bash
mkdir -p /tmp/tl-migration && cd /tmp/tl-migration

curl -fLO https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.16/install/sql/mysql/testlink_create_tables.sql
curl -fLO https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.16/install/sql/mysql/testlink_create_default_data.sql
```

Einspielen, in dieser Reihenfolge (erst Struktur, dann Daten — Daten brauchen die Tabellen, die die erste
Datei anlegt):

```bash
mysql -u tl_login -p testlink < testlink_create_tables.sql
mysql -u tl_login -p testlink < testlink_create_default_data.sql
```

**Verifikation** — der Schema-Stand ist jetzt exakt wie in der Produktion:

```bash
mysql -u tl_login -p testlink -e "SELECT * FROM db_version ORDER BY upgrade_ts;"
```

## Schritt 4: Versions-Migrationen der Reihe nach einspielen

Jede Version zwischen 1.9.16 (unsere Ausgangslage) und 1.9.20 (unser Ziel) hat einen eigenen Satz
SQL-Dateien unter `install/sql/alter_tables/<version>/mysql/DB.<version>/`, aufgeteilt in `step1/`
(Schema- und Funktions-Änderungen) und `stepZ/` (schließt die Migration ab und trägt die neue Version in
`db_version` ein). **Die Reihenfolge innerhalb einer Version ist wichtig**: erst `step1`, dann `stepZ`.

Um das Prinzip zu verstehen, hier **eine** Version komplett von Hand:

```bash
curl -fLO https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.20-20251208/install/sql/alter_tables/1.9.17/mysql/DB.1.9.17/step1/db_schema_update.sql
curl -fLO https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.20-20251208/install/sql/alter_tables/1.9.17/mysql/DB.1.9.17/step1/db_udf_update.sql
curl -fLO https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.20-20251208/install/sql/alter_tables/1.9.17/mysql/DB.1.9.17/stepZ/z_final_step.sql

mysql -u tl_login -p testlink < db_schema_update.sql
mysql -u tl_login -p testlink < db_udf_update.sql
mysql -u tl_login -p testlink < z_final_step.sql

mysql -u tl_login -p testlink -e "SELECT * FROM db_version ORDER BY upgrade_ts DESC LIMIT 1;"
```

Der letzte Befehl sollte jetzt `DB 1.9.17` zeigen. Genau dasselbe Muster wiederholt sich für `1.9.18`,
`1.9.19` und `1.9.20` — nur die Versionsnummer in der URL und den Dateinamen ändert sich. Da du das
Prinzip jetzt verstanden hast, macht ein kleines Skript den Rest **nachvollziehbar automatisiert** statt
stumpf drei weitere Male copy-paste:

```bash
for VERSION in 1.9.18 1.9.19 1.9.20; do
  echo "=== Migriere auf $VERSION ==="
  BASE_URL="https://raw.githubusercontent.com/TestLinkOpenSourceTRMS/testlink-code/1.9.20-20251208/install/sql/alter_tables/${VERSION}/mysql/DB.${VERSION}"

  curl -fL "${BASE_URL}/step1/db_schema_update.sql" -o step1_schema.sql
  curl -fL "${BASE_URL}/step1/db_udf_update.sql" -o step1_udf.sql
  curl -fL "${BASE_URL}/stepZ/z_final_step.sql" -o stepZ.sql

  mysql -u tl_login -p testlink < step1_schema.sql
  mysql -u tl_login -p testlink < step1_udf.sql
  mysql -u tl_login -p testlink < stepZ.sql

  mysql -u tl_login -p testlink -e "SELECT * FROM db_version ORDER BY upgrade_ts DESC LIMIT 1;"
done
```

!!! info "Hinweis zu Tabellen-Präfixen"
    Die SQL-Dateien enthalten `/*prefix*/` vor jedem Tabellennamen — ein Platzhalter, den TestLinks
    eigener SQL-Parser normalerweise durch einen konfigurierten Tabellen-Präfix ersetzt. `/* ... */` ist
    in SQL ein Kommentar, den die Datenbank beim direkten Einspielen einfach ignoriert — das ergibt genau
    dann das richtige Ergebnis, wenn du (wie in dieser Anleitung durchgehend) **keinen** Tabellen-Präfix
    konfiguriert hast. Falls deine Produktivinstanz einen Präfix verwendet, musst du `/*prefix*/` vorher
    per `sed` durch den echten Präfix ersetzen.

## Schritt 5: Die aktualisierte Codebasis mit dieser Datenbank verbinden

Jetzt kommt der Teil, den du aus Kapitel 5–7 schon kennst — nur mit MySQL statt PostgreSQL als Ziel.
Falls noch nicht vorhanden, TestLink `1.9.20-20251208` wie in [Kapitel 5](../installation/05-testlink-source.md)
herunterladen und entpacken (z. B. nach `/var/www/testlink-migration-test`, damit es deine
PostgreSQL-Instanz aus den vorherigen Kapiteln nicht überschreibt).

Anders als in Kapitel 7 rufst du **nicht** den Web-Installer auf — die Datenbank ist ja schon vollständig
migriert. Stattdessen legst du `config_db.inc.php` **von Hand** an (genau die Datei, die der
Web-Installer in Kapitel 7 sonst automatisch erzeugt hätte):

```php
<?php
$tlCfg->db_type = 'mysqli';
$tlCfg->db_host = 'localhost';
$tlCfg->db_name = 'testlink';
$tlCfg->db_user = 'tl_login';
$tlCfg->db_pass = 'DeinStarkesPasswort123!';
```

Speichere das als `/var/www/testlink-migration-test/config_db.inc.php` und passe Besitzer/Rechte wie in
[Kapitel 6](../installation/06-virtualhost.md) beschrieben an (`www-data:www-data`). Richte einen zweiten VirtualHost
dafür ein (analog Kapitel 6, anderer `ServerName`/Port), rufe die Seite im Browser auf — **kein**
`install/`, direkt die normale TestLink-Oberfläche sollte erscheinen.

## Verifikation

```bash
mysql -u tl_login -p testlink -e "SELECT * FROM db_version ORDER BY upgrade_ts DESC LIMIT 1;"
```

Erwartung: `DB 1.9.20`. Im Browser: TestLink lädt normal, Login-Seite erscheint, keine Fehlermeldungen zu
fehlendem Schema. Falls du mit `testlink_create_default_data.sql` gearbeitet hast, kannst du dich mit dem
darin enthaltenen Standard-Admin-Zugang einloggen (siehe TestLink-Dokumentation für die Standard-Zugangsdaten
dieser Version — in Produktion später natürlich mit den echten Zugangsdaten deines Kollegen-Dumps).

## Was du gelernt hast

- MariaDB ist auf Debian der Standard-Ersatz für MySQL, mit denselben Kommandozeilenwerkzeugen.
- Ein TestLink-Versions-Update ist eine Reihe klar abgegrenzter SQL-Skripte pro Version, die man in
  fester Reihenfolge (`step1` vor `stepZ`) einspielt.
- Nach jedem Schritt lässt sich der Fortschritt über `db_version` verifizieren — ein eingebauter
  Prüfpunkt, den man aktiv nutzen sollte, statt blind weiterzumachen.
- `config_db.inc.php` kann auch von Hand geschrieben werden — der Web-Installer aus Kapitel 7 erzeugt
  am Ende nur genau diese Datei.

## Verständnis-Check

1. Warum spielst du `testlink_create_tables.sql` vor `testlink_create_default_data.sql` ein und nicht
   umgekehrt?
2. Woran erkennst du nach jedem Versionssprung, dass er erfolgreich war?
3. Warum reicht es hier, `config_db.inc.php` von Hand zu schreiben, statt den Web-Installer zu benutzen?

Weiter mit [Migrations-Kapitel 3: Schritt 2 – Von MySQL zu PostgreSQL migrieren](03-schritt2-db-wechsel.md).
