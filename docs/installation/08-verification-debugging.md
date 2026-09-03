# 8 – Verifikation & Debugging-Handwerkszeug

## Ziel dieses Kapitels

Dieses Kapitel ist bewusst kein weiterer Installationsschritt, sondern eine **Werkzeugkiste**. Als Azubi
ist die Fähigkeit, systematisch einzugrenzen "wo genau hakt es", wertvoller als jede Einzellösung — die
folgenden Werkzeuge nutzt du bei jedem der vorherigen Kapitel und bei jedem zukünftigen Server-Problem.

## Die Grundfrage bei jedem Fehler: Welche Schicht ist betroffen?

Unser Stack hat mehrere Schichten übereinander — bei einem Problem hilft es, sie einzeln von unten nach
oben zu prüfen, statt zu raten:

```
Browser  →  Netzwerk/DNS  →  Apache  →  PHP  →  PostgreSQL
```

Ein Fehler in `psql` bedeutet z. B., dass Apache/PHP völlig irrelevant sind — das Problem liegt tiefer.
Ein "weiße Seite im Browser, aber `curl localhost` auf dem Server funktioniert" deutet dagegen eher auf
Netzwerk/Firewall zwischen dir und dem Server als auf die Anwendung selbst.

## Dienststatus prüfen

```bash
sudo systemctl status apache2
sudo systemctl status postgresql
```

`active (running)` = Dienst läuft. `failed` oder `inactive` = hier ist dein Problem. Die letzten Log-Zeilen
stehen direkt unter dem Status mit angezeigt.

## Logs lesen — die wichtigste Fähigkeit

### Apache-Logs

```bash
sudo tail -n 50 /var/log/apache2/error.log
sudo tail -n 50 /var/log/apache2/testlink-error.log   # unser eigenes Log aus Kapitel 6
```

`tail -n 50` zeigt die letzten 50 Zeilen — bei einem frischen Fehler meist ausreichend, ohne die ganze
(oft sehr lange) Log-Datei durchsuchen zu müssen. Für **live mitlesen**, während du im Browser etwas
auslöst:

```bash
sudo tail -f /var/log/apache2/testlink-error.log
```

`-f` (follow) hält die Anzeige offen und zeigt neue Zeilen sofort an, sobald sie geschrieben werden —
öffne ein zweites Terminal-Fenster, lade parallel die Seite im Browser neu, und beobachte in Echtzeit, was
passiert. Mit `Strg+C` beendest du das Mitlesen.

### systemd-Journal (für alle Dienste, inkl. PostgreSQL)

```bash
sudo journalctl -u postgresql -n 50           # letzte 50 Zeilen für den postgresql-Dienst
sudo journalctl -u apache2 -f                 # live mitlesen
sudo journalctl -u postgresql --since "10 min ago"
```

`journalctl` ist systemds zentrales Log-Werkzeug — jeder von systemd verwaltete Dienst (`-u <dienstname>`)
landet dort, unabhängig davon, ob der Dienst zusätzlich eigene Log-Dateien schreibt.

### PHP/TestLink-eigene Logs

```bash
sudo tail -n 50 /var/www/testlink/logs/*.log
```

## Konfiguration testen, bevor du neu startest

Aus den vorherigen Kapiteln bereits bekannt, hier nochmal als generelles Prinzip:

```bash
sudo apache2ctl configtest   # Apache-Syntax pruefen, VOR restart/reload
```

Für PostgreSQL gibt es kein direktes Äquivalent — dort merkst du Syntaxfehler in der Konfiguration am
fehlgeschlagenen Neustart, den du dann über `journalctl -u postgresql` diagnostizierst.

## Netzwerk-Ebene prüfen

```bash
sudo ss -tlnp | grep -E ':80|:5432'
```

`ss` (socket statistics, moderner Nachfolger von `netstat`) mit `-t` (TCP), `-l` (nur lauschende Sockets),
`-n` (numerisch, keine Namensauflösung), `-p` (welcher Prozess). Zeigt dir, ob überhaupt etwas auf Port 80
(Apache) bzw. 5432 (PostgreSQL) lauscht — und welcher Prozess. Lauscht nichts auf einem erwarteten Port,
ist der Dienst entweder nicht gestartet oder an eine andere Adresse gebunden.

## Verbindung Schicht für Schicht testen

```bash
# 1. Läuft PostgreSQL und akzeptiert es Verbindungen?
psql -h 127.0.0.1 -U postgres -c '\conninfo'

# 2. Reagiert Apache überhaupt?
curl -I http://localhost/

# 3. Wird PHP tatsächlich ausgeführt (nicht nur als Text ausgeliefert)?
curl -s http://localhost/ | head -c 200   # sollte HTML zeigen, kein sichtbares "<?php"

# 4. Von AUSSEN erreichbar (von deinem eigenen Rechner, nicht der VM)?
curl -I http://<ip-der-vm>/
```

Wenn Schritt 2 auf der VM selbst funktioniert, aber Schritt 4 von deinem Rechner aus nicht: Das Problem
liegt zwischen deinem Rechner und der VM (Firewall, falsches Netzwerk/Bridge in Proxmox, falsche IP) — nicht
in Apache/PHP/PostgreSQL selbst.

## Dateirechte schnell diagnostizieren

```bash
sudo -u www-data test -w /var/www/testlink && echo "www-data kann schreiben" || echo "www-data KANN NICHT schreiben"
```

`sudo -u www-data <befehl>` führt einen Befehl **als der Benutzer `www-data`** aus — damit testest du exakt
die Rechte, die Apache/PHP tatsächlich hätten, statt dich auf `ls -la` und Kopfrechnen zu verlassen.

## Konkrete Fehlerbilder aus diesem Projekt

Ein paar Fehler, die beim Durcharbeiten dieses Lernpfads typisch sind, mit direkter Lösung — nutze das
oben gelernte Handwerkszeug, um sie selbst zu bestätigen, statt die Lösung blind zu übernehmen.

**„Failed! ... pgsql cannot be used" im Installer-Systemcheck** — die PHP-Erweiterung `pgsql` fehlt:

```bash
sudo apt-get install -y php-pgsql
sudo systemctl restart apache2
php -m | grep pgsql
```

**Weiße Seite / Fatal Error nach dem Öffnen von TestLink** — meist ein PHP-8-Kompatibilitätsproblem
(z. B. bei Verwendung des alten offiziellen Tags `1.9.20` statt `1.9.20-20251208`):

```bash
tail -n 50 /var/log/apache2/error.log
```

Tauchen dort Fehler zu entfernten PHP-Funktionen auf (z. B. `create_function`, dynamische Properties),
sicherstellen, dass `TL_VERSION=1.9.20-20251208` (oder neuer) in `.env` gesetzt war, bevor
`scripts/04-deploy-testlink.sh` lief, und ggf. mit dem korrekten Tag neu deployen.

**„Could not create database" / „Could not create user" im Web-Installer:**

- PostgreSQL-Verbindung testen: `psql -h 127.0.0.1 -U postgres -c '\conninfo'` (Passwort =
  `PG_SUPERUSER_PASSWORD`)
- Stimmt das im Installer eingegebene Administrator-Passwort mit dem in `.env` gesetzten überein?
- Läuft PostgreSQL überhaupt? `systemctl status postgresql`
- `pg_hba.conf` prüfen: gibt es eine `host ... 127.0.0.1/32 scram-sha-256` (oder `md5`) Zeile? (siehe
  [Kapitel 4](04-postgresql.md))

**Apache zeigt „It works!" oder Debian-Default-Seite statt TestLink** — der VirtualHost wurde nicht
aktiviert, oder `TL_DOMAIN`/Port stimmen nicht mit dem Aufruf überein:

```bash
sudo apache2ctl -S          # zeigt aktive VirtualHosts
sudo a2ensite testlink.conf
sudo systemctl reload apache2
```

**„Permission denied" beim Schreiben von `config_db.inc.php` während der Installation** — `www-data`
hat keinen Schreibzugriff auf das Zielverzeichnis:

```bash
ls -la /var/www/testlink | head
sudo chown -R www-data:www-data /var/www/testlink
```

**Diagramme/Charts werden nicht angezeigt** — `gd`-Extension fehlt, nicht kritisch für den Betrieb:

```bash
sudo apt-get install -y php-gd
sudo systemctl restart apache2
```

**Installation komplett neu starten:**

1. `install/` wieder sichtbar machen (falls schon mit `scripts/99-lock-installer.sh` gesperrt):
   ```bash
   sudo mv /var/www/testlink/install.DISABLED /var/www/testlink/install
   ```
2. Alte Datenbank/User in PostgreSQL löschen (als `postgres`-Superuser):
   ```bash
   sudo -u postgres psql -c "DROP DATABASE IF EXISTS testlink;"
   sudo -u postgres psql -c "DROP USER IF EXISTS tl_login;"
   ```
3. `config_db.inc.php` im Zielverzeichnis löschen, falls vorhanden.
4. Web-Installer erneut aufrufen (siehe [Kapitel 7](07-web-installer.md)).

## Was du gelernt hast

- Bei mehrschichtigen Systemen (Netzwerk → Webserver → Anwendung → Datenbank) systematisch von unten nach
  oben (oder von der Fehlermeldung ausgehend gezielt) prüfen, statt zu raten.
- `journalctl -u <dienst>` ist der zentrale Log-Zugang für alle systemd-Dienste, unabhängig von
  anwendungseigenen Logs.
- `tail -f` und `journalctl -f` zeigen Logs in Echtzeit — die effizienteste Methode, ein Problem beim
  Reproduzieren live zu beobachten.
- `ss -tlnp` zeigt dir, ob und von welchem Prozess ein Port tatsächlich belegt ist.
- `sudo -u www-data <befehl>` testet Rechte exakt aus Sicht des Webserver-Prozesses.

## Verständnis-Check

1. Du bekommst im Browser eine weiße Seite. Nenne drei Befehle, mit denen du eingrenzt, in welcher Schicht
   das Problem liegt.
2. Warum ist `sudo -u www-data test -w <pfad>` aussagekräftiger als `ls -la <pfad>` und Kopfrechnen?
3. `curl -I http://localhost/` funktioniert auf der VM, aber `curl -I http://<ip>/` von deinem eigenen
   Rechner aus nicht. In welcher Schicht suchst du zuerst?

Weiter mit [Kapitel 9: Absichern & Brücke zu Prod](09-hardening-and-prod.md).
