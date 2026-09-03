# Performance-Tuning: Wenn die Demo-Konfiguration nicht mehr reicht

## Kurzfassung

Die in diesem Repo aufgebaute Demo-Konfiguration (`mod_php` + MPM `prefork`, PostgreSQL mit
Standardwerten) ist bewusst einfach gehalten. Diese Seite erklärt die **nächsten Schritte**, falls eure
TestLink-Instanz genug Last bekommt, dass das nicht mehr reicht — und vor allem *warum* diese Schritte
überhaupt etwas bringen.

## Warum diese Seite anders ist als die übrigen Grundlagen-Seiten

Die anderen Seiten in diesem Ordner erklären ein einzelnes Werkzeug. Performance-Probleme entstehen aber
fast nie an einer einzelnen Stelle — sie sind das Zusammenspiel von Apache, PHP und PostgreSQL unter
Last. Diese Seite ist deshalb bewusst **werkzeugübergreifend**.

## Engpass 1: `mod_php` + `prefork` skaliert nicht beliebig

**Warum das ein Engpass ist:** Wie in [`apache.md`](apache.md) erklärt, bindet bei `prefork` jeder
gleichzeitige Request einen kompletten Apache-Prozess — inklusive des kompletten eingebetteten
PHP-Interpreters. Bei vielen gleichzeitigen Nutzern braucht das viel Arbeitsspeicher, und die maximale
Anzahl paralleler Requests ist hart durch `MaxRequestWorkers` begrenzt (siehe
[`operations/03-performance-monitoring.md`](../operations/03-performance-monitoring.md)).

**Die Lösung: PHP-FPM.** PHP-FPM (**F**astCGI **P**rocess **M**anager) betreibt PHP als eigenständigen
Prozess-Pool, getrennt von Apache. Apache reicht Anfragen über das FastCGI-Protokoll weiter
(`mod_proxy_fcgi`), statt PHP direkt einzubetten. Dadurch kann Apache beim schnelleren, asynchronen MPM
`event` bleiben (mehr gleichzeitige *Verbindungen*, nicht nur *aktive* Requests), während PHP-FPM seinen
eigenen, unabhängig konfigurierbaren Worker-Pool verwaltet.

```bash
sudo apt-get install -y php-fpm libapache2-mod-fcgid
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php*-fpm
sudo a2dismod php* mpm_prefork
sudo a2enmod mpm_event
sudo systemctl restart apache2 php*-fpm
```

(Die VirtualHost-Konfiguration muss danach angepasst werden, PHP-Requests an FPM statt an `mod_php`
weiterzureichen — nicht Teil der Demo-Skripte in diesem Repo.)

**Wichtige PHP-FPM-Stellschrauben** (in `/etc/php/*/fpm/pool.d/www.conf`):

- `pm.max_children` — maximale Anzahl gleichzeitiger PHP-Worker-Prozesse (das FPM-Äquivalent zu
  Apaches `MaxRequestWorkers`).
- `pm = dynamic` vs. `pm = static` — dynamisch startet/stoppt Worker je nach Bedarf (spart Ressourcen
  bei schwankender Last), statisch hält immer dieselbe Anzahl bereit (vorhersagbarer, aber
  ressourcenhungriger im Leerlauf).

## Engpass 2: Zu viele PostgreSQL-Verbindungen

**Warum das ein Engpass ist:** Jede offene PostgreSQL-Verbindung kostet Arbeitsspeicher auf dem
Datenbankserver, unabhängig davon, ob gerade eine Abfrage läuft. Viele gleichzeitige TestLink-Requests
(egal ob über `mod_php`-Prozesse oder PHP-FPM-Worker) können schnell gegen `max_connections` laufen
(siehe [`postgresql.md`](postgresql.md) und
[`operations/03-performance-monitoring.md`](../operations/03-performance-monitoring.md)).

**Die Lösung: Connection Pooling** (z. B. mit `pgbouncer`). Ein Pooler sitzt zwischen Anwendung und
PostgreSQL und hält eine kleinere Anzahl **wiederverwendeter** Datenbankverbindungen offen, statt für
jeden PHP-Request/-Prozess eine neue Verbindung aufzumachen und wieder zu schließen — das spart sowohl
die Verbindungen selbst als auch den (nicht trivialen) Aufwand, eine PostgreSQL-Verbindung überhaupt
neu aufzubauen.

```bash
sudo apt-get install -y pgbouncer
```

Grundprinzip der Konfiguration (`/etc/pgbouncer/pgbouncer.ini`): TestLink verbindet sich nicht mehr
direkt mit PostgreSQL (Port 5432), sondern mit `pgbouncer` (Standard-Port 6432), das die eigentlichen
Verbindungen zu PostgreSQL im Hintergrund verwaltet und wiederverwendet — für TestLink selbst ändert
sich dabei nur der Port in `config_db.inc.php`.

## Wann lohnt sich das überhaupt?

Für eine kleine bis mittlere TestLink-Instanz (ein Team, wenige gleichzeitige Nutzer) ist die
Demo-Konfiguration aus diesem Repo völlig ausreichend — vorzeitige Optimierung für eine Last, die nie
eintritt, ist verschwendete Komplexität. Die Signale aus
[`operations/03-performance-monitoring.md`](../operations/03-performance-monitoring.md) (Apache-Worker
regelmäßig ausgelastet, PostgreSQL-Verbindungen nahe am Limit) sind der richtige Zeitpunkt, um diese
Seite wieder aufzuschlagen — nicht vorher.

## Was du gelernt hast

- Performance-Probleme sind meist Zusammenspiel mehrerer Werkzeuge, nicht die Schuld eines einzelnen.
- PHP-FPM entkoppelt PHP-Ausführung von Apache-Prozessen — mehr Kontrolle, aber eine bewegliche
  Komponente mehr als `mod_php`.
- Connection Pooling (`pgbouncer`) reduziert den Overhead vieler kurzlebiger Datenbankverbindungen,
  ohne dass sich für TestLink selbst viel ändert (nur der Zielport).
- Diese Optimierungen lohnen sich erst, wenn die Monitoring-Werte aus `operations/03` das tatsächlich
  nahelegen — nicht vorsorglich.

## Bezug zu unserem Projekt

- [`apache.md`](apache.md) — warum `mod_php` an `prefork` gekoppelt ist
- [`postgresql.md`](postgresql.md) — Grundlagen zu Verbindungen und Rollen
- [`operations/03-performance-monitoring.md`](../operations/03-performance-monitoring.md) — woran du
  erkennst, dass diese Seite relevant wird
- [`installation/09-hardening-and-prod.md`](../installation/09-hardening-and-prod.md) — erste Erwähnung
  von PHP-FPM als Prod-Option
