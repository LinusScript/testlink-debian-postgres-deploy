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
