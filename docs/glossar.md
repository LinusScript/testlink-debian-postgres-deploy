# Glossar

Zentrale, alphabetische Sammlung der Fachbegriffe aus diesem Repo — zum schnellen Nachschlagen, wenn dir
ein Wort begegnet und du nicht die ganze Seite noch mal lesen willst. Jeder Eintrag verlinkt zur
ausführlichen Erklärung mit Hintergrund/Beispiel; hier steht bewusst nur die Kurzfassung.

## A

**Apache-Modul** — zuschaltbare Zusatzfunktion für den Webserver Apache (`mod_php`, `mod_rewrite`, ...),
über `a2enmod`/`a2dismod` aktiviert/deaktiviert. → [`grundlagen/apache.md`](grundlagen/apache.md)

**autovacuum** — PostgreSQLs automatischer Hintergrundprozess, der ungültig markierte Zeilen aufräumt
(siehe MVCC). → [`operations/05-common-issues.md`](operations/05-common-issues.md)

## C

**Connection Pooling** — eine begrenzte Anzahl wiederverwendeter Datenbankverbindungen statt vieler
kurzlebiger Einzelverbindungen (z. B. mit `pgbouncer`). →
[`grundlagen/performance-tuning.md`](grundlagen/performance-tuning.md)

**Custom Fields** — von der eigenen Organisation frei definierbare Zusatzfelder an TestLink-Testfällen/
-Projekten. → [`grundlagen/testlink.md`](grundlagen/testlink.md)

## D

**db_version** — TestLinks eigene Tabelle, die den aktuellen Datenbank-Schema-Stand verfolgt,
unabhängig von der Code-Version. → [`migration/01-konzept.md`](migration/01-konzept.md)

**Distribution (Linux)** — Kombination aus Linux-Kernel, Paketverwaltung und Systemprogrammen,
gebrauchsfertig kombiniert (z. B. Debian). → [`grundlagen/debian-linux.md`](grundlagen/debian-linux.md)

**DocumentRoot** — das Verzeichnis, aus dem ein Apache-VirtualHost Dateien ausliefert. →
[`grundlagen/apache.md`](grundlagen/apache.md)

## E

**Erweiterung/Extension (PHP)** — zusätzliche Fähigkeit, die PHP nicht im Kern mitbringt, sondern
gezielt installiert wird (z. B. `php-pgsql`). → [`grundlagen/php.md`](grundlagen/php.md)

## I

**information_schema** — eine in MySQL/MariaDB immer vorhandene Datenbank mit Metadaten über alle
anderen Datenbanken (z. B. welche Tabellen existieren). →
[`grundlagen/mariadb-mysql.md`](grundlagen/mariadb-mysql.md)

**Interpreter** — das Programm, das Code (z. B. PHP) zur Laufzeit liest und ausführt, ohne separaten
Kompilierschritt. → [`grundlagen/php.md`](grundlagen/php.md)

## K

**Kernel (Linux)** — der Betriebssystem-Kern, verwaltet Prozessorzeit, Speicher, Geräte, Dateisysteme,
Netzwerk. → [`grundlagen/debian-linux.md`](grundlagen/debian-linux.md)

## M

**MPM (Multi-Processing Module)** — bestimmt, wie Apache mehrere gleichzeitige Anfragen bearbeitet
(`prefork` = ein Prozess pro Anfrage, `event` = asynchron). → [`grundlagen/apache.md`](grundlagen/apache.md)

**MVCC** — PostgreSQLs Nebenläufigkeitsmodell: gelöschte/geänderte Zeilen werden zunächst nur als
ungültig markiert, nicht sofort entfernt, damit gleichzeitige Lesevorgänge nicht blockiert werden. →
[`operations/05-common-issues.md`](operations/05-common-issues.md)

## P

**pg_hba.conf** — PostgreSQLs zentrale Zugriffssteuerungsdatei: wer darf sich von wo aus wie anmelden. →
[`grundlagen/postgresql.md`](grundlagen/postgresql.md)

**PHP-FPM** — FastCGI Process Manager, betreibt PHP als eigenständigen Prozess-Pool statt eingebettet in
Apache. → [`grundlagen/performance-tuning.md`](grundlagen/performance-tuning.md)

**pm.max_children** — PHP-FPM-Einstellung für die maximale Anzahl gleichzeitiger PHP-Worker-Prozesse. →
[`grundlagen/performance-tuning.md`](grundlagen/performance-tuning.md)

## R

**Rechte (TestLink)** — granulare Einzelberechtigungen (z. B. `mgt_modify_tc`), aus denen sich Rollen
zusammensetzen. → [`operations/01-user-management.md`](operations/01-user-management.md)

**Rolle (PostgreSQL)** — PostgreSQLs einheitliches Konzept für Benutzer *und* Gruppen (`ROLE`). →
[`grundlagen/postgresql.md`](grundlagen/postgresql.md)

**Rolle (TestLink)** — eine der sechs Standard-Zuweisungen (admin, leader, senior tester, tester, test
designer, guest) pro Benutzer *und Projekt*. → [`operations/01-user-management.md`](operations/01-user-management.md)

## S

**Schema (PostgreSQL)** — ein Namensraum innerhalb einer Datenbank (Standard: `public`) — nicht zu
verwechseln mit „Datenbank-Schema" im Sinne von Tabellenstruktur. → [`grundlagen/postgresql.md`](grundlagen/postgresql.md)

**Sequenz (PostgreSQL)** — Mechanismus für automatisch hochzählende ID-Spalten, das Gegenstück zu
MySQLs `AUTO_INCREMENT`. → [`grundlagen/postgresql.md`](grundlagen/postgresql.md)

**Storage Engine (MySQL/MariaDB)** — legt fest, *wie* Daten physisch gespeichert werden (Standard:
`InnoDB`). → [`grundlagen/mariadb-mysql.md`](grundlagen/mariadb-mysql.md)

**Superuser (PostgreSQL)** — die Rolle `postgres`, darf uneingeschränkt alles. →
[`grundlagen/postgresql.md`](grundlagen/postgresql.md)

**systemd** — Debians Init-System, verwaltet alle Dienste (Apache, PostgreSQL, SSH, ...) über `systemctl`.
→ [`grundlagen/debian-linux.md`](grundlagen/debian-linux.md)

## T

**Test-Management-System (TMS)** — Oberbegriff für Software wie TestLink (Alternativen: TestRail,
Zephyr, qTest). → [`grundlagen/testlink.md`](grundlagen/testlink.md)

**Testfall-Version (`tcversion`)** — TestLink versioniert Testfälle bei jeder Änderung, alte Versionen
bleiben nachvollziehbar erhalten. → [`grundlagen/testlink.md`](grundlagen/testlink.md)

**Typ-Cast (pgloader)** — automatische Übersetzung eines MySQL-Datentyps in den passenden
PostgreSQL-Typ (z. B. `TINYINT(1)` → `BOOLEAN`). → [`grundlagen/pgloader.md`](grundlagen/pgloader.md)

## U

**unix_socket-Authentifizierung** — MariaDBs Gegenstück zu PostgreSQLs `peer`-Auth: vertraut lokal dem
angemeldeten Linux-Benutzer, ohne Passwort. → [`grundlagen/mariadb-mysql.md`](grundlagen/mariadb-mysql.md)

## V

**VACUUM** — der SQL-Befehl, mit dem PostgreSQL manuell zum Aufräumen (siehe MVCC) angestoßen wird. →
[`operations/05-common-issues.md`](operations/05-common-issues.md)

**VirtualHost** — eine in sich abgeschlossene Website-Konfiguration innerhalb eines Apache-Prozesses
(eigener `DocumentRoot`, eigener Hostname). → [`grundlagen/apache.md`](grundlagen/apache.md)

## Fehlt ein Begriff?

Dieses Glossar wächst mit dem Repo — wenn dir beim Lesen ein Fachbegriff begegnet, der hier fehlt,
ergänze ihn (Definition + Link zur Stelle, an der er ausführlich erklärt wird), statt ihn beim nächsten
Mal wieder nachschlagen zu müssen.
