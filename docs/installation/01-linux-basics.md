# 1 – Linux-Grundlagen für dieses Projekt

## Ziel dieses Kapitels

Das Handwerkszeug, das du in **jedem** der folgenden Kapitel brauchst: Rechte erhöhen, Pakete installieren,
Dienste steuern, Dateirechte verstehen. Kein vollständiger Linux-Kurs — nur das, was für dieses Projekt
direkt relevant ist.

## `sudo` — warum arbeiten wir nicht als `root`?

Du bist auf der VM als dein eigener Benutzer eingeloggt, nicht als `root`. Für Aktionen, die Root-Rechte
brauchen (Pakete installieren, Systemdateien ändern, Dienste neu starten), stellst du dem Befehl `sudo`
voran:

```bash
sudo apt-get update
```

**Warum nicht einfach dauerhaft als root arbeiten?** Ein Tippfehler in einem Root-Befehl (z. B.
`rm -rf /irgendwas`) kann als normaler Benutzer meist nur deine eigenen Dateien zerstören — als root
potenziell das ganze System. `sudo` erhöht Rechte **gezielt für einen einzelnen Befehl**, das ist die
gängige Praxis auf jedem Debian-/Ubuntu-Server, auch produktiv.

Falls dein Benutzer bei der Debian-Installation nicht automatisch `sudo`-Rechte bekommen hat: als `root`
einloggen (`su -`) und ausführen:

```bash
apt-get install -y sudo
usermod -aG sudo <dein-benutzername>
```

Danach einmal aus- und wieder einloggen, damit die Gruppenmitgliedschaft aktiv wird.

## `apt` — Debians Paketverwaltung

Debian-Software kommt aus **Paketen** — vorgefertigten, signierten Bündeln aus Programm + Metadaten
(Version, Abhängigkeiten). `apt` verwaltet sie:

```bash
sudo apt-get update          # Paketlisten der konfigurierten Quellen aktualisieren (NICHT die Pakete selbst!)
sudo apt-get upgrade -y      # installierte Pakete auf die neueste verfügbare Version bringen
sudo apt-get install -y <paketname>   # ein Paket installieren
apt-cache search <suchbegriff>        # nach Paketen suchen
dpkg -l | grep <suchbegriff>          # prüfen, was bereits installiert ist
```

**Wichtiger Unterschied**: `apt-get update` lädt nur die *Liste* verfügbarer Pakete/Versionen neu (aus
`/etc/apt/sources.list` bzw. `/etc/apt/sources.list.d/`) — es installiert nichts. Deswegen läuft es vor
jedem `install`/`upgrade`, damit du wirklich die aktuellsten Versionen bekommst.

## `systemctl` — Dienste steuern

Debian nutzt **systemd** als Init-System — das ist der erste Prozess, der beim Booten startet und alle
weiteren Dienste (Apache, PostgreSQL, SSH, ...) verwaltet. Du sprichst damit über `systemctl`:

```bash
sudo systemctl status apache2     # Läuft der Dienst? Letzte Log-Zeilen
sudo systemctl start apache2      # Dienst jetzt starten
sudo systemctl stop apache2       # Dienst jetzt stoppen
sudo systemctl restart apache2    # Dienst komplett neu starten (kurzer Ausfall)
sudo systemctl reload apache2     # Konfiguration neu einlesen OHNE Verbindungsabbruch (wo unterstützt)
sudo systemctl enable apache2     # Dienst beim Booten automatisch starten
```

**`restart` vs. `reload`**: `restart` beendet den Prozess komplett und startet ihn neu — kurzzeitig nicht
erreichbar, aber garantiert alle Änderungen aktiv. `reload` schickt dem laufenden Prozess ein Signal, die
Konfiguration neu einzulesen, ohne Verbindungsabbruch — geht nicht bei jeder Art von Änderung (z. B. nicht,
wenn sich geladene Module ändern). Als Faustregel in dieser Anleitung: nach **Paket-/Modul-Änderungen**
`restart`, nach reinen **Konfigurationsdatei-Änderungen** reicht meist `reload`.

## Dateirechte — der Teil, der später die meisten Fehler verursacht

Jede Datei/jedes Verzeichnis unter Linux hat einen **Besitzer** (User), eine **Gruppe** und **Rechte**
für drei Kategorien: Besitzer, Gruppe, Alle anderen.

```bash
ls -la /var/www/
```

Beispielausgabe:

```
drwxr-xr-x  3 www-data www-data 4096 Aug 30 10:00 testlink
```

Gelesen von links:
- `d` = Verzeichnis (bei Dateien steht hier `-`)
- `rwx` (Besitzer `www-data`) = lesen, schreiben, ausführen/betreten
- `r-x` (Gruppe `www-data`) = lesen, betreten, **nicht** schreiben
- `r-x` (Andere) = lesen, betreten, **nicht** schreiben

**Warum ist das für uns wichtig?** Apache läuft auf Debian standardmäßig als Benutzer **`www-data`**
(nicht als root, aus Sicherheitsgründen — ein kompromittierter Webserver-Prozess soll möglichst wenig
Schaden anrichten können). Wenn TestLink-Dateien nicht `www-data` gehören, kann Apache/PHP sie nicht lesen
oder — für den Installer entscheidend — nicht in sie hineinschreiben (z. B. `config_db.inc.php`).

Die zwei Befehle, die du dafür ständig brauchst:

```bash
sudo chown -R www-data:www-data /var/www/testlink   # Besitzer (User:Gruppe) rekursiv setzen
sudo chmod 755 /var/www/testlink                     # Rechte setzen (hier: rwx für Besitzer, r-x für Rest)
```

`chmod`-Zahlen: jede Ziffer ist eine Bit-Summe aus **4 (lesen) + 2 (schreiben) + 1 (ausführen)**.
`755` = Besitzer `7` (4+2+1 = rwx), Gruppe `5` (4+1 = r-x), Andere `5` (r-x). `644` = Besitzer liest+schreibt,
alle anderen nur lesen (typisch für normale Dateien, die nicht ausführbar sein müssen).

## Umgebungsvariablen und `.env`-Dateien

Ein Befehl wie

```bash
export TL_VERSION=1.9.20-20251208
```

setzt eine **Umgebungsvariable** — ein Wert, auf den nachfolgende Befehle/Skripte in derselben Sitzung
zugreifen können (`$TL_VERSION`). Die `.env`-Datei in diesem Repo ist nur eine Textdatei mit
`SCHLÜSSEL=WERT`-Zeilen, die die Skripte per `source .env` einlesen — in diesem Lernpfad tippen wir Werte
stattdessen direkt in die Befehle, damit du siehst, was wirklich passiert.

## Was du gelernt hast

- `sudo` erhöht Rechte für einen einzelnen Befehl, statt dauerhaft als root zu arbeiten.
- `apt-get update` aktualisiert nur die Paketliste, `upgrade`/`install` installieren tatsächlich Software.
- `systemctl` steuert Dienste über systemd; `restart` vs. `reload` hat unterschiedliche Auswirkungen.
- Apache/PHP laufen als `www-data` — Dateirechte/Besitzer sind der häufigste Stolperstein bei Webservern.
- `.env`-Dateien sind simple Key-Value-Textdateien, die Skripte in Umgebungsvariablen laden.

## Verständnis-Check

1. Was ist der Unterschied zwischen `apt-get update` und `apt-get upgrade`?
2. Warum würde Apache eine Datei nicht lesen können, die `chmod 600` hat und `root:root` gehört?
3. Wann reicht `systemctl reload` nicht aus und du brauchst `restart`?

Weiter mit [Kapitel 2: Apache von Hand installieren](02-apache.md).
