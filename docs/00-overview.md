# 00 – Überblick & Architektur

## Ziel

Eine reproduzierbare, dokumentierte Installation von TestLink auf einem Debian-Server mit PostgreSQL, die als
Demo dient und identisch (nur mit anderen Zugangsdaten/Domains) auf einem Produktivserver wiederholt werden kann.

## Komponenten

| Komponente | Rolle | Version (Demo) |
|---|---|---|
| Debian | Betriebssystem | 13 „Trixie" |
| Apache 2 (mod_php, MPM prefork) | Webserver, führt PHP aus | aus Debian-Repos |
| PHP | Anwendungslaufzeit für TestLink | 8.4 (Debian-Trixie-Default) |
| PostgreSQL | Datenbank | 17 (Debian-Trixie-Default) |
| TestLink | Test-Management-System (PHP-Anwendung) | Tag `1.9.20-20251208` |

## Warum diese Kombination?

- **Debian 13 (Trixie)** bringt PHP 8.4 und PostgreSQL 17 direkt aus den offiziellen Paketquellen mit — keine
  Fremd-Repos (z. B. Sury) nötig, was Wartung und Reproduzierbarkeit auf einem Produktivserver vereinfacht.
- **TestLinks offizieller Tag `1.9.20` (Jan 2020)** ist für PHP 7.2–7.4 geschrieben und läuft auf PHP 8.4 nicht
  zuverlässig (viele in PHP 8 entfernte/geänderte Sprachfeatures). Der neuere Community-Tag **`1.9.20-20251208`**
  wurde laut Changelog "partially tested with 8.5.0, with Smarty 3.x" — also gezielt auf Kompatibilität zu
  modernem PHP hin gepflegt. Deswegen ist er in `.env` als Standard hinterlegt.
- **mod_php + MPM prefork** statt PHP-FPM, weil das dem klassischen, von TestLink dokumentierten Setup am
  nächsten kommt und für eine Demo/kleine Prod-Instanz ausreicht. Für höhere Last kann später auf PHP-FPM
  umgestellt werden (siehe [`07-production-notes.md`](07-production-notes.md)).

## Wie TestLink seine Datenbank bekommt

Wichtig für das Verständnis der folgenden Schritte: **TestLink legt seine eigene Datenbank und seinen eigenen
Datenbank-User selbst an** — und zwar über den Browser-basierten Web-Installer (`install/installNewDB.php`
im TestLink-Quellcode), nicht über ein manuell auszuführendes SQL-Skript.

Der Ablauf ist:

1. Du richtest PostgreSQL ein und vergibst nur ein Passwort für den PostgreSQL-Superuser `postgres`.
2. Im Web-Installer trägst du dieses Superuser-Passwort als "Datenbank-Administrator"-Zugang ein.
3. TestLink verbindet sich damit, legt die Datenbank (`testlink`) und einen eigenen, weniger privilegierten
   DB-User (z. B. `tl_login`) an, importiert das Schema (`install/sql/postgres/*.sql`) und schreibt anschließend
   die Zugangsdaten in `config_db.inc.php` im Installationsverzeichnis.

Das bedeutet: Es gibt in diesem Repo **kein Skript, das `CREATE DATABASE` für TestLink ausführt** — das macht
der Installer. Die Skripte hier bereiten nur die Infrastruktur (Pakete, Postgres-Superuser-Passwort, Apache
VirtualHost, entpackter Quellcode) so vor, dass der Web-Installer reibungslos durchlaufen kann.

## Ablauf in diesem Repo

```
01 Server vorbereiten  →  02 Apache/PHP  →  03 PostgreSQL  →  04 TestLink entpacken + VirtualHost
        →  05 Web-Installer im Browser durchklicken  →  06 absichern  →  (07 Prod-Hinweise)
```
