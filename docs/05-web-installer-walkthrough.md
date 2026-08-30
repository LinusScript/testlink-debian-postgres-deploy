# 05 – Web-Installer durchklicken

Dieser Schritt ist bewusst **manuell im Browser** (nicht automatisiert), weil TestLink dafür keinen
offiziellen CLI-Modus anbietet — der Installer ist ein PHP-Web-Assistent.

Rufe im Browser auf:

```
http://<TL_DOMAIN oder Server-IP>/install/
```

## Schritt A – Systemcheck (`installCheck.php`)

Zeigt eine Tabelle mit PHP-Version, Erweiterungen (`pgsql`, `gd`, `curl`, `json`, `ldap`, ...), Schreibrechten
und PHP-Einstellungen (`max_execution_time`, `memory_limit`). Alles, was hier rot markiert ist, muss vor dem
Fortfahren behoben werden (siehe [`02-dependencies.md`](02-dependencies.md) und
[`08-troubleshooting.md`](08-troubleshooting.md)). Gelbe Warnungen (z. B. Diagramme ohne `gd`) sind für eine
Demo meist tolerierbar.

Klicke **Continue**.

## Schritt B – Datenbank-Zugangsdaten (`installDbInput.php`)

Trage hier ein:

| Feld | Wert |
|---|---|
| **Database type** | `Postgres (9.1 and later)` |
| **Database Administrator Login** | `postgres` |
| **Database Administrator Password** | dein `PG_SUPERUSER_PASSWORD` aus `.env` |
| **Database Host** | `127.0.0.1` (bzw. `PG_HOST`) |
| **Database name** | `testlink` (bzw. `TL_DB_NAME`) |
| **TestLink Database Login** | `tl_login` (bzw. `TL_DB_USER`) |
| **TestLink Database Password** | dein `TL_DB_PASSWORD` aus `.env` |

Diese Werte werden **nicht** aus `.env` automatisch übernommen — `.env` dient dir hier nur als Notizzettel,
damit du beim Ausfüllen konsistente, dir bekannte Werte einträgst.

## Schritt C – Installation (`installNewDB.php` / `installStart.php`)

TestLink verbindet sich als `postgres`-Superuser, legt die Datenbank `testlink` sowie den DB-User `tl_login`
an, importiert das PostgreSQL-Schema (`install/sql/postgres/*.sql`) und schreibt die Zugangsdaten in
`config_db.inc.php`. Am Ende zeigt die Seite den Login-Link zur TestLink-Oberfläche sowie
Standard-Zugangsdaten für den Administrator-Account (Benutzername meist `admin`) — notiere sie sofort und
ändere das Passwort direkt nach dem ersten Login.

## Schritt D – Erste Anmeldung

Logge dich mit dem im letzten Schritt angezeigten Admin-Zugang ein, ändere sofort das Passwort
(Benutzerverwaltung → eigenes Profil), und lege bei Bedarf weitere Benutzer an.

Danach weiter mit [`06-post-install-hardening.md`](06-post-install-hardening.md).
