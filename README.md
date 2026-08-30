# TestLink auf Debian mit PostgreSQL

Schritt-für-Schritt-Anleitung und Automatisierungsskripte, um [TestLink](https://github.com/TestLinkOpenSourceTRMS/testlink-code)
(Test-Management-System) auf Debian mit **PostgreSQL** als Datenbank zu installieren — zunächst als Demo, mit dem Ziel,
den exakt gleichen Prozess später produktiv nachzubauen.

TestLink wird offiziell primär mit MySQL/MariaDB dokumentiert und containerisiert (siehe `docker-compose.yml` im Original-Repo).
PostgreSQL wird vom Web-Installer aber vollständig unterstützt (`install/installDbInput.php`, `install/installNewDB.php`,
`install/sql/postgres/`). Dieses Repo geht bewusst den PostgreSQL-Weg auf einem "echten" Debian-Server (kein Docker),
weil das dem geplanten Produktiv-Setup am nächsten kommt.

## Warum kein Docker?

Das offizielle `Dockerfile`/`docker-compose.yml` von TestLink ist auf MySQL zugeschnitten (PHP 7.4, `mysqli`-Extension,
kein PostgreSQL-Pfad). Für "Debian-Server + PostgreSQL, später 1:1 in Prod" ist eine native Installation der direktere Weg
und leichter 1:1 auf einen Produktivserver zu übertragen (Root-Server, VM, o.ä.).

## Verzeichnisstruktur

```
docs/       Schritt-für-Schritt-Anleitung (in der Reihenfolge 00 → 08 lesen)
scripts/    Bash-Skripte, die die Anleitung automatisieren
.env.example  Konfigurationsvariablen (Version, Domain, Passwörter, Pfade)
```

## Schnellstart (Demo)

1. Debian-Server (getestet für **Debian 13 „Trixie"**) bereitstellen, per SSH einloggen.
2. Dieses Repo auf den Server klonen.
3. `.env.example` nach `.env` kopieren und Werte anpassen (**mindestens die Passwörter ändern!**).
4. Skripte der Reihe nach als root ausführen (oder `scripts/00-run-all.sh` für alles auf einmal):

   ```bash
   cp .env.example .env
   nano .env   # Passwörter/Domain anpassen
   sudo ./scripts/00-run-all.sh
   ```
5. Browser-Installer unter `http://<server-ip-oder-domain>/install/` öffnen und der Anleitung in
   [`docs/05-web-installer-walkthrough.md`](docs/05-web-installer-walkthrough.md) folgen.
6. Nach erfolgreicher Installation: [`docs/06-post-install-hardening.md`](docs/06-post-install-hardening.md) durchgehen.

Für die Übertragung auf eine Produktivumgebung siehe [`docs/07-production-notes.md`](docs/07-production-notes.md) —
dort stehen die Punkte, die sich zwischen Demo und Prod unterscheiden sollten (Domain/TLS, getrennter DB-Host,
Backups, Monitoring, Updates).

## Anleitung im Detail

| Schritt | Dokument | Skript |
|---|---|---|
| 0 | [Überblick & Architektur](docs/00-overview.md) | – |
| 1 | [Server-Vorbereitung](docs/01-server-preparation.md) | `scripts/01-prepare-system.sh` |
| 2 | [Apache & PHP installieren](docs/02-dependencies.md) | `scripts/02-install-apache-php.sh` |
| 3 | [PostgreSQL einrichten](docs/03-postgresql-setup.md) | `scripts/03-install-postgresql.sh` |
| 4 | [TestLink deployen](docs/04-testlink-deployment.md) | `scripts/04-deploy-testlink.sh` |
| 5 | [Web-Installer durchklicken](docs/05-web-installer-walkthrough.md) | – (manuell im Browser) |
| 6 | [Absichern nach der Installation](docs/06-post-install-hardening.md) | `scripts/99-lock-installer.sh` |
| 7 | [Hinweise für Produktivbetrieb](docs/07-production-notes.md) | – |
| 8 | [Troubleshooting](docs/08-troubleshooting.md) | – |

## Getestete Version

Standardmäßig wird der neueste Tag des Repos verwendet: **`1.9.20-20251208`** (Stand: neuester verfügbarer Tag,
laut Changelog "partially tested with 8.5.0, with Smarty 3.x" — also der Tag mit der besten Kompatibilität zu
modernem PHP, wie es Debian 13 mitbringt). Die Version ist in `.env` über `TL_VERSION` änderbar.

## Lizenzhinweis

TestLink selbst steht unter GPLv2+. Die Skripte und die Dokumentation in diesem Repo sind eigenständiges
Automatisierungsmaterial für die Installation.
