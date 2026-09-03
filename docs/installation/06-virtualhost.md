# 6 – Apache-VirtualHost von Hand schreiben

## Ziel dieses Kapitels

Apache liefert TestLink unter einer eigenen, sauberen Adresse aus (`http://<domain-oder-ip>/`), statt es
nur als Unterordner der Standard-Seite erreichbar zu haben.

## Was ist ein VirtualHost?

Ein einzelner Apache-Prozess kann **mehrere Websites gleichzeitig** ausliefern — jede mit eigenem
`DocumentRoot` (welches Verzeichnis auf der Platte ausgeliefert wird), eigenem `ServerName` (unter welchem
Hostnamen sie erreichbar ist) und eigener Log-Datei. Diese "virtuellen Server" heißen **VirtualHosts**.
Das ist derselbe Mechanismus, der es einem einzigen Server erlaubt, z. B. `shop.beispiel.de` und
`blog.beispiel.de` parallel auszuliefern.

## Wie Apache Konfigurationsdateien organisiert

```bash
ls /etc/apache2/sites-available/
ls /etc/apache2/sites-enabled/
```

- **`sites-available/`**: alle definierten VirtualHost-Konfigurationen — ob aktiv oder nicht.
- **`sites-enabled/`**: enthält nur **Symlinks** auf die aktiven Konfigurationen aus `sites-available/`.

Das ist dasselbe Muster wie bei `mods-available`/`mods-enabled` aus Kapitel 2 — Debians durchgängiges
Konzept, um Konfigurationen zu definieren, ohne sie sofort zu aktivieren.

## Schritt 1: VirtualHost-Datei anlegen

```bash
sudo nano /etc/apache2/sites-available/testlink.conf
```

(Falls `nano` dir nicht liegt: `vim` oder ein anderer Editor deiner Wahl funktioniert genauso.)

Inhalt (ersetze `testlink.demo.local` durch deine gewünschte Domain oder lass es für eine reine
IP-basierte Demo notfalls auch weg — dazu gleich mehr):

```apache
<VirtualHost *:80>
    ServerName testlink.demo.local
    DocumentRoot /var/www/testlink

    <Directory /var/www/testlink>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/testlink-error.log
    CustomLog ${APACHE_LOG_DIR}/testlink-access.log combined
</VirtualHost>
```

Zeile für Zeile erklärt:

- **`<VirtualHost *:80>`**: Diese Konfiguration gilt für eingehende Verbindungen auf Port 80, egal über
  welche IP-Adresse des Servers sie ankommen (`*`).
- **`ServerName`**: Der Hostname, unter dem dieser VirtualHost angesprochen werden soll. Wichtig, sobald du
  mehrere VirtualHosts auf demselben Server hast — Apache entscheidet anhand des `Host`-Headers der
  HTTP-Anfrage, welcher VirtualHost zuständig ist (**Name-based Virtual Hosting**).
- **`DocumentRoot`**: das Verzeichnis auf der Festplatte, aus dem Dateien für diesen VirtualHost
  ausgeliefert werden — hier unser in Kapitel 5 entpackter TestLink-Code.
- **`<Directory ...>` … `</Directory>`**: Zugriffsregeln, die *speziell* für dieses Verzeichnis gelten
  (Apache erlaubt pro Verzeichnis unterschiedliche Regeln, nicht nur pro VirtualHost).
  - `Options FollowSymLinks`: erlaubt Apache, symbolischen Links innerhalb des Verzeichnisses zu folgen.
  - `AllowOverride All`: erlaubt `.htaccess`-Dateien im Verzeichnis, Apache-Einstellungen lokal zu
    überschreiben (TestLink liefert eigene `.htaccess`-Regeln mit, u. a. für `mod_rewrite` aus Kapitel 2).
  - `Require all granted`: erlaubt grundsätzlich jedem Zugriff auf dieses Verzeichnis (Apache 2.4-Syntax;
    das Gegenteil wäre z. B. eine IP-Einschränkung).
- **`ErrorLog`/`CustomLog`**: eigene Log-Dateien für diesen VirtualHost statt der globalen
  `/var/log/apache2/error.log` — praktisch, um Fehler gezielt einer Anwendung zuzuordnen, wenn mehrere
  Seiten auf demselben Server laufen. `${APACHE_LOG_DIR}` ist eine von Debian gesetzte Apache-interne
  Variable, die auf `/var/log/apache2` zeigt.

## Wenn du (noch) keine echte Domain hast

Für eine reine Demo im lokalen Netz kannst du:

- Auf deinem eigenen Rechner in `/etc/hosts` (Linux/macOS) bzw.
  `C:\Windows\System32\drivers\etc\hosts` (Windows) eine Zeile ergänzen:
  ```
  <ip-der-vm>  testlink.demo.local
  ```
  Danach ist `http://testlink.demo.local/` von deinem Rechner aus erreichbar, ohne einen echten DNS-Eintrag
  zu brauchen.
- Oder du rufst einfach die IP direkt auf (`http://<ip-der-vm>/`) — dann greift dieser VirtualHost trotzdem,
  weil `<VirtualHost *:80>` alle IPs auf Port 80 abdeckt und (bei nur einem VirtualHost) automatisch der
  einzige Kandidat ist.

## Schritt 2: VirtualHost aktivieren

```bash
sudo a2ensite testlink.conf
```

`a2ensite` erstellt den Symlink von `sites-available/testlink.conf` nach `sites-enabled/testlink.conf` —
genau das Muster aus Kapitel 2 mit `a2enmod`.

Optional, aber sauberer: die mitgelieferte Debian-Standardseite deaktivieren, damit sie nicht mit unserem
VirtualHost um dieselbe IP/Port-Kombination konkurriert:

```bash
sudo a2dissite 000-default.conf
```

## Schritt 3: Testen und neu laden

```bash
sudo apache2ctl configtest
sudo systemctl reload apache2
```

Hier reicht `reload` (statt `restart`) — wir haben nur eine Konfigurationsdatei geändert, kein Modul
hinzugefügt oder entfernt (vgl. die Erklärung in Kapitel 1).

## Verifikation

```bash
sudo apache2ctl -S
```

Zeigt dir alle aktiven VirtualHosts inklusive der Datei, aus der sie geladen wurden — praktisch, um zu
prüfen, ob `testlink.conf` wirklich aktiv ist und keine andere Konfiguration ungewollt Vorrang hat.

```bash
curl -I http://localhost/
```

Sollte jetzt (noch ohne fertige TestLink-Installation) entweder eine Weiterleitung auf `install/` oder
zumindest eine `200`/`302`-Antwort liefern — nicht mehr die alte Debian-Standardseite.

## Was du gelernt hast

- VirtualHosts erlauben einem Apache-Prozess, mehrere Websites mit eigenen DocumentRoots/Hostnamen
  auszuliefern.
- Debians `sites-available`/`sites-enabled`-Muster trennt "definiert" von "aktiv" — identisch zum
  Modul-Konzept aus Kapitel 2.
- `<Directory>`-Blöcke erlauben verzeichnisspezifische Zugriffsregeln innerhalb eines VirtualHosts.
- `/etc/hosts` erlaubt lokale Domain-Namensauflösung ohne echten DNS-Eintrag — praktisch für Demos.

## Verständnis-Check

1. Was ist der Unterschied zwischen `sites-available/` und `sites-enabled/`?
2. Wozu dient `AllowOverride All`, und warum braucht TestLink das?
3. Was würde passieren, wenn zwei aktive VirtualHosts denselben `ServerName` und denselben Port hätten?

Weiter mit [Kapitel 7: Web-Installer durchklicken](07-web-installer.md).
