# 7 – Web-Installer durchklicken

## Ziel dieses Kapitels

TestLink ist vollständig installiert: Datenbank angelegt, Schema importiert, Admin-Account eingerichtet,
du kannst dich einloggen.

## Warum ein Browser-Assistent statt eines CLI-Befehls?

TestLink bietet (Stand des hier verwendeten Tags) keinen offiziellen unbeaufsichtigten
Kommandozeilen-Installer — die Installation läuft über eine Reihe von PHP-Skripten unter `install/`, die
dich durch Systemcheck → Datenbank-Zugangsdaten → tatsächliche Installation führen und dabei mit deiner
Browser-Session (`$_SESSION`) Zustand zwischen den Seiten weiterreichen.

Öffne im Browser:

```
http://<deine-domain-oder-ip>/install/
```

## Schritt A: Systemcheck (`installCheck.php`)

Diese Seite ruft im Hintergrund genau die Prüfungen auf, die wir in den Kapiteln 3 und 4 bereits manuell
verifiziert haben (PHP-Version, Erweiterungen `pgsql`/`gd`/`curl`/`json`/`ldap`, Schreibrechte,
`max_execution_time`, `memory_limit`). Weil du diese Kapitel durchgearbeitet hast, sollte hier alles grün
sein — falls doch etwas Rotes/Gelbes auftaucht, ist das ein guter Anlass, zurück ins jeweilige Kapitel zu
gehen und zu verstehen, was fehlt, statt blind ein Paket nachzuinstallieren.

Klicke **Continue**.

## Schritt B: Datenbank-Zugangsdaten (`installDbInput.php`)

Trage ein:

| Feld | Wert | Bezug zu vorherigen Kapiteln |
|---|---|---|
| **Database type** | `Postgres (9.1 and later)` | – |
| **Database Administrator Login** | `postgres` | die Rolle aus Kapitel 4 |
| **Database Administrator Password** | dein Passwort aus Kapitel 4, Schritt 3 | – |
| **Database Host** | `127.0.0.1` | dieselbe TCP-Verbindung, die du in Kapitel 4, Schritt 5 manuell getestet hast |
| **Database name** | `testlink` (frei wählbar, wird gleich neu angelegt) | – |
| **TestLink Database Login** | `tl_login` (frei wählbar) | – |
| **TestLink Database Password** | ein **neues**, eigenes starkes Passwort | – |

**Wichtig:** Das "TestLink Database Password" ist bewusst ein **anderes** Passwort als das
`postgres`-Superuser-Passwort — TestLink läuft im laufenden Betrieb mit dem eingeschränkten `tl_login`-User,
nicht mit dem Superuser (**Prinzip der geringsten Rechte** — ein kompromittierter Webserver-Prozess soll
maximal auf "seine" Datenbank zugreifen können, nicht auf den gesamten PostgreSQL-Server).

## Schritt C: Was beim Klick auf "Install" wirklich passiert

Aus dem TestLink-Quellcode (`install/installNewDB.php`) — gut zu wissen, damit du im Fehlerfall verstehst,
wo du suchen musst:

1. TestLink verbindet sich **als `postgres`-Superuser** (deine Eingaben aus Schritt B) und legt die
   Datenbank an (`CREATE DATABASE`).
2. Es legt die Rolle `tl_login` mit dem von dir vergebenen Passwort an.
3. Für PostgreSQL wechselt TestLink danach explizit zur neuen `tl_login`-Rolle (**nicht** mehr der
   Superuser), um das Schema zu importieren — die SQL-Dateien liegen unter `install/sql/postgres/` im
   TestLink-Code.
4. Am Ende schreibt TestLink eine neue Datei **`config_db.inc.php`** ins Installationsverzeichnis — das ist
   die Datei, die die eben gewählten Zugangsdaten dauerhaft speichert und bei jedem späteren Seitenaufruf
   von `config.inc.php` automatisch eingelesen wird (`@include_once('config_db.inc.php')`).

Das ist auch der Grund, warum `chown www-data:www-data /var/www/testlink` in Kapitel 5 zwingend nötig war:
Ohne Schreibrecht auf das Verzeichnis würde Schritt 4 hier mit "Permission denied" scheitern.

## Schritt D: Abschluss und erste Anmeldung

Nach erfolgreicher Installation zeigt dir die letzte Seite einen Link zur TestLink-Oberfläche sowie
Standard-Zugangsdaten für den Administrator (meist Benutzername `admin`). **Notiere sie sofort.**

Logge dich ein, gehe direkt in dein Benutzerprofil und ändere das Passwort — der Standard-Zugang ist
öffentlich dokumentiert (jeder, der TestLink kennt, kennt ihn auch) und darf nicht aktiv bleiben.

## Verifikation

```bash
ls -la /var/www/testlink/config_db.inc.php
sudo -u postgres psql -c "\l" | grep testlink   # zeigt die neu angelegte Datenbank in der Liste aller DBs
sudo -u postgres psql -c "\du" | grep tl_login  # zeigt die neu angelegte Rolle
```

`\l` (list databases) und `\du` (list users/roles) sind `psql`-Metabefehle — sie beginnen mit `\` statt
mit SQL-Syntax und werden direkt von `psql` selbst interpretiert, nicht an den Server als SQL geschickt.

## Was du gelernt hast

- TestLinks Installer legt Datenbank **und** eingeschränkten DB-User selbst an — mit zwei getrennten
  Rollen: Superuser für die Einrichtung, eingeschränkter User für den laufenden Betrieb.
- `config_db.inc.php` ist die persistente Konfigurationsdatei, die danach bei jedem Request eingelesen wird.
- `psql`-Metabefehle (`\l`, `\du`, `\conninfo`, `\q`) sind Client-seitige Kurzbefehle, kein SQL.

## Verständnis-Check

1. Warum verbindet sich TestLink für `CREATE DATABASE` als `postgres`, aber für den Schema-Import als
   `tl_login`?
2. Was wäre die Konsequenz, wenn TestLink im laufenden Betrieb weiterhin mit dem `postgres`-Superuser
   arbeiten würde, statt mit `tl_login`?
3. Wo genau werden die DB-Zugangsdaten nach der Installation gespeichert, und was passiert, wenn diese
   Datei fehlt oder falsche Werte enthält?

Weiter mit [Kapitel 8: Verifikation & Debugging-Handwerkszeug](08-verification-debugging.md).
