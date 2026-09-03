# TestLink auf Debian mit PostgreSQL

Schritt-für-Schritt-Anleitung und Automatisierungsskripte, um [TestLink](https://github.com/TestLinkOpenSourceTRMS/testlink-code)
(Test-Management-System) auf Debian mit **PostgreSQL** als Datenbank zu installieren — zunächst als Demo, mit dem Ziel,
den exakt gleichen Prozess später produktiv nachzubauen.

## Der reale Hintergrund

Das ist kein rein hypothetisches Übungsprojekt: Produktiv läuft aktuell **TestLink 1.9.16 auf
MySQL/MariaDB**, Ziel ist die Migration auf PostgreSQL. Kapitel 0–9 des Lernpfads bauen zunächst die
**Zielumgebung** (aktuelle TestLink-Version + PostgreSQL) als Demo auf; Kapitel 10–13 bilden anschließend
die **eigentliche Migration** nach — Konzept, App-Upgrade, DB-Engine-Wechsel und ein vollständiger
Verifikations-/Produktivdaten-Leitfaden (Datei-Anhänge, echter `mysqldump`, alle Tabellen statt
Stichproben) — mit Erklärung der Hintergründe, nicht nur der Befehle. Start:
[`docs/tutorial/10-migrationskonzept.md`](docs/tutorial/10-migrationskonzept.md).

TestLink wird offiziell primär mit MySQL/MariaDB dokumentiert und containerisiert (siehe `docker-compose.yml` im Original-Repo).
PostgreSQL wird vom Web-Installer aber vollständig unterstützt (`install/installDbInput.php`, `install/installNewDB.php`,
`install/sql/postgres/`). Dieses Repo geht bewusst den PostgreSQL-Weg auf einem "echten" Debian-Server (kein Docker),
weil das dem geplanten Produktiv-Setup am nächsten kommt.

## Warum kein Docker?

Das offizielle `Dockerfile`/`docker-compose.yml` von TestLink ist auf MySQL zugeschnitten (PHP 7.4, `mysqli`-Extension,
kein PostgreSQL-Pfad). Für "Debian-Server + PostgreSQL, später 1:1 in Prod" ist eine native Installation der direktere Weg
und leichter 1:1 auf einen Produktivserver zu übertragen (Root-Server, VM, o.ä.).

## Drei Wege durch dieses Repo

| Weg | Für wen | Start |
|---|---|---|
| **📚 Grundlagen** | Du willst *bevor* du tippst verstehen, was PHP, Apache, PostgreSQL, MySQL/MariaDB, pgloader und Debian überhaupt sind, woher sie kommen und wofür sie da sind | [`docs/grundlagen/README.md`](docs/grundlagen/README.md) |
| **🎓 Lernpfad** | Du willst jeden Befehl selbst tippen und verstehen (z. B. als Azubi), inkl. Erstellung der Debian-VM in Proxmox VE | [`docs/tutorial/README.md`](docs/tutorial/README.md) |
| **⚡ Schnellstart** | Du hast das Prinzip schon verstanden (oder willst es später auf einem zweiten/Prod-Server schnell wiederholen) | Skripte unten in diesem README |

Alle drei bauen auf **demselben Stack** (Debian + Apache/mod_php + PostgreSQL + TestLink) auf — die
Grundlagen erklären *was* die Werkzeuge sind, der Lernpfad erklärt *wie* man sie einsetzt (jeder Schritt
einzeln von Hand), die Skripte automatisieren exakt das Gleiche. Empfohlene Reihenfolge: Grundlagen →
Lernpfad → (später) Skripte.

## Verzeichnisstruktur

```
docs/grundlagen/  Was PHP, Apache, PostgreSQL, MySQL/MariaDB, pgloader, Debian sind und wofür sie da sind
docs/tutorial/    Lernpfad: jeder Schritt einzeln erklärt, inkl. Proxmox-VM + Migration (00 → 13)
docs/             Kompakte Referenz: was die Skripte tun (00 → 08)
scripts/          Bash-Skripte, die die Anleitung automatisieren
.env.example      Konfigurationsvariablen (Version, Domain, Passwörter, Pfade)
```

## Schnellstart (Demo, automatisiert)

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
