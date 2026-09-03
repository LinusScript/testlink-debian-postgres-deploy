# TestLink auf Debian mit PostgreSQL

Dokumentierte, reproduzierbare Migration von [TestLink](https://github.com/TestLinkOpenSourceTRMS/testlink-code)
(Test-Management-System) von einer produktiven **1.9.16-Instanz auf MySQL/MariaDB** zu einer aktuellen
Version auf **PostgreSQL**, auf **Debian** — zuerst als Demo auf einer eigenen VM getestet, mit dem Ziel,
denselben Weg anschließend 1:1 produktiv nachzuvollziehen.

## Was ist TestLink, falls du es nicht kennst?

TestLink ist eine webbasierte Software, mit der Teams Testfälle für die Qualitätssicherung planen,
organisieren, ausführen und die Ergebnisse auswerten — statt das über Excel-Tabellen zu machen. Eine
ausführliche, allgemeinverständliche Erklärung mit Beispiel gibt es unter
[`docs/grundlagen/testlink.md`](docs/grundlagen/testlink.md).

## Der reale Hintergrund

Das ist kein rein hypothetisches Übungsprojekt: Produktiv läuft aktuell TestLink 1.9.16 auf
MySQL/MariaDB, Ziel ist die Migration auf PostgreSQL. Dieses Repo bildet beide Hälften der Aufgabe ab:

1. **Die Zielumgebung aufbauen** (Debian + Apache + PHP + PostgreSQL + aktuelle TestLink-Version) —
   [`docs/installation/`](docs/installation/README.md).
2. **Die eigentliche Migration** von der alten Produktivumgebung dorthin — mit Konzept, App-Upgrade,
   Datenbank-Engine-Wechsel und einem vollständigen Verifikations-/Produktivdaten-Leitfaden —
   [`docs/migration/`](docs/migration/README.md).

TestLink wird offiziell primär mit MySQL/MariaDB dokumentiert und containerisiert (siehe
`docker-compose.yml` im Original-Repo). PostgreSQL wird vom Web-Installer aber vollständig unterstützt
(`install/installDbInput.php`, `install/installNewDB.php`, `install/sql/postgres/`). Dieses Repo geht
bewusst den PostgreSQL-Weg auf einem "echten" Debian-Server (kein Docker), weil das dem geplanten
Produktiv-Setup am nächsten kommt.

### Warum kein Docker?

Das offizielle `Dockerfile`/`docker-compose.yml` von TestLink ist auf MySQL zugeschnitten (PHP 7.4,
`mysqli`-Extension, kein PostgreSQL-Pfad). Für "Debian-Server + PostgreSQL, später 1:1 in Prod" ist eine
native Installation der direktere Weg und leichter 1:1 auf einen Produktivserver zu übertragen
(Root-Server, VM, o. ä.).

## Repo-Struktur

```
docs/
  grundlagen/     Was PHP, Apache, PostgreSQL, MySQL/MariaDB, pgloader, Debian und TestLink selbst
                  sind, woher sie kommen und wofür sie da sind — lies das zuerst.
  installation/   Schritt-für-Schritt-Anleitung für die Zielumgebung, jeder Befehl einzeln erklärt
                  (inkl. Proxmox-VM-Erstellung), Kapitel 0–9.
  migration/      Die eigentliche Migration (1.9.16/MySQL → aktuelle Version/PostgreSQL),
                  Kapitel 1–4, setzt auf installation/ auf.
scripts/          Bash-Skripte, die installation/ 0–9 automatisieren (Referenz für Prod, oder um
                  die Demo schnell zu wiederholen).
.env.example      Konfigurationsvariablen (Version, Domain, Passwörter, Pfade).
```

## Wie du dieses Repo liest

| Wenn du... | dann lies... |
|---|---|
| TestLink und die einzelnen Werkzeuge erst **verstehen** willst, bevor du tippst | [`docs/grundlagen/`](docs/grundlagen/README.md), beginnend mit [testlink.md](docs/grundlagen/testlink.md) |
| die Zielumgebung **selbst aufbauen** willst, jeden Befehl einzeln erklärt | [`docs/installation/`](docs/installation/README.md) |
| die **eigentliche Migration** (1.9.16/MySQL → PostgreSQL) durcharbeiten willst | [`docs/migration/`](docs/migration/README.md) (setzt auf `installation/` auf) |
| das Prinzip schon kennst und es **automatisiert** wiederholen willst (Demo neu, zweiter Server, ...) | Skripte, siehe unten |

Empfohlene Reihenfolge beim ersten Durcharbeiten: **Grundlagen → Installation → Migration.**

## Schnellstart (automatisiert)

Für alle, die die Zielumgebung nicht von Hand nachbauen, sondern per Skript aufsetzen wollen:

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
   [`docs/installation/07-web-installer.md`](docs/installation/07-web-installer.md) folgen.
6. Nach erfolgreicher Installation: [`docs/installation/09-hardening-and-prod.md`](docs/installation/09-hardening-and-prod.md) durchgehen.
7. Für die eigentliche Migration von der Produktivumgebung: [`docs/migration/`](docs/migration/README.md).

## Skripte im Detail

| Skript | Entspricht Installations-Kapitel |
|---|---|
| `scripts/01-prepare-system.sh` | [1 – Linux-Grundlagen](docs/installation/01-linux-basics.md) |
| `scripts/02-install-apache-php.sh` | [2 – Apache](docs/installation/02-apache.md), [3 – PHP](docs/installation/03-php.md) |
| `scripts/03-install-postgresql.sh` | [4 – PostgreSQL](docs/installation/04-postgresql.md) |
| `scripts/04-deploy-testlink.sh` | [5 – TestLink-Quellcode](docs/installation/05-testlink-source.md), [6 – VirtualHost](docs/installation/06-virtualhost.md) |
| `scripts/99-lock-installer.sh` | [9 – Absichern](docs/installation/09-hardening-and-prod.md) |
| `scripts/compare-migration-rowcounts.sh` | [Migrations-Kapitel 4 – Vollständigkeits-Check](docs/migration/04-vollstaendigkeit-produktivmigration.md) |

Kapitel 0 (Proxmox-VM) und 7 (Web-Installer) sind bewusst nicht automatisiert — die VM-Erstellung ist
UI-Klickarbeit in Proxmox, der Web-Installer ein Browser-Assistent.

## Getestete Version

Standardmäßig wird der neueste Tag des Repos verwendet: **`1.9.20-20251208`** (Stand: neuester verfügbarer
Tag, laut Changelog "partially tested with 8.5.0, with Smarty 3.x" — also der Tag mit der besten
Kompatibilität zu modernem PHP, wie es Debian 13 mitbringt). Die Version ist in `.env` über `TL_VERSION`
änderbar.

## Lizenzhinweis

TestLink selbst steht unter GPLv2+. Die Skripte und die Dokumentation in diesem Repo sind eigenständiges
Automatisierungsmaterial für die Installation.
