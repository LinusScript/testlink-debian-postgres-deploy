# 3 – PHP von Hand installieren

## Ziel dieses Kapitels

PHP ist installiert, Apache führt `.php`-Dateien tatsächlich aus (nicht nur als Text-Download), und alle
für TestLink nötigen Erweiterungen sind aktiv.

## Was ist PHP, und wie hängt es mit Apache zusammen?

PHP ist eine Skriptsprache, die serverseitig ausgeführt wird: Der Nutzer sieht nur das Ergebnis (HTML),
nicht den PHP-Quellcode. Mit `mod_php` (dem Modul, das wir gleich installieren) bettet sich der
PHP-Interpreter **direkt in den Apache-Prozess** ein — deswegen die Kopplung an das MPM `prefork` aus
Kapitel 2: Jeder Apache-Worker-Prozess bekommt seinen eigenen eingebetteten PHP-Interpreter.

Ablauf einer Anfrage auf eine `.php`-Datei:

1. Browser fragt `index.php` an.
2. Apache erkennt anhand der Dateiendung (konfiguriert über `mod_php`), dass die Datei durch den
   PHP-Interpreter laufen muss statt direkt ausgeliefert zu werden.
3. PHP führt den Code aus (z. B. Datenbankabfragen, Logik), erzeugt HTML.
4. Apache schickt das erzeugte HTML als Antwort an den Browser.

## Schritt 1: PHP und die benötigten Erweiterungen installieren

PHP selbst kann relativ wenig — die meiste Funktionalität kommt über **Erweiterungen** (Extensions), die
du gezielt dazu installierst. TestLink prüft beim ersten Aufruf des Web-Installers selbst, welche
Erweiterungen vorhanden sind (`install/installCheck.php` im TestLink-Quellcode) — daraus ergibt sich diese
Liste:

| Paket | Wofür TestLink es braucht |
|---|---|
| `php` | Der PHP-Interpreter selbst (auf Debian 13 automatisch Version 8.4) |
| `libapache2-mod-php` | Bindet PHP als Apache-Modul ein (siehe oben) |
| `php-pgsql` | **Pflicht** für uns: Kommunikation mit PostgreSQL |
| `php-gd` | Diagramme/Grafiken in Testreports; ohne läuft TestLink, aber ohne Charts |
| `php-curl` | REST-Integration mit Bugtrackern (Pflicht laut Installer-Check) |
| `php-mbstring` | Korrekte Verarbeitung von Mehrbyte-Zeichen (Umlaute, Unicode) — wichtig für Templating |
| `php-xml` | XML-Verarbeitung (u. a. Import/Export-Funktionen) |
| `php-zip` | ZIP-Handling (Anhänge, Exporte) |
| `php-ldap` | Optional: nur nötig, falls du später LDAP-Login einsetzen willst |

```bash
sudo apt-get install -y \
  php \
  libapache2-mod-php \
  php-pgsql \
  php-gd \
  php-curl \
  php-mbstring \
  php-xml \
  php-zip \
  php-ldap
```

`json` und `curl`-Unterstützung im PHP-Kern sind bei modernen PHP-Versionen meist schon eingebaut/aktiv —
das prüfst du gleich mit.

## Schritt 2: Modul aktivieren und Apache neu starten

Bei den meisten Debian-PHP-Paketen aktiviert das `apt-get install` das Apache-Modul bereits automatisch.
Zur Sicherheit trotzdem explizit:

```bash
sudo a2enmod php8.4    # exakter Modulname haengt von der installierten PHP-Version ab, siehe naechster Befehl
```

Falls du unsicher bist, wie das Modul genau heißt:

```bash
ls /etc/apache2/mods-available/ | grep php
```

Dann:

```bash
sudo apache2ctl configtest
sudo systemctl restart apache2
```

## Schritt 3: Verifizieren, dass Apache PHP wirklich ausführt

Erstelle eine Testdatei im Apache-Standardverzeichnis:

```bash
echo '<?php phpinfo();' | sudo tee /var/www/html/info.php
```

`tee` schreibt die Standardeingabe sowohl in eine Datei als auch auf den Bildschirm — praktisch in
Kombination mit `sudo`, weil `echo '...' | sudo ...` (Umleitung *nach* `sudo`) sonst an Berechtigungen
scheitern würde: Die Shell öffnet die Ziel-Datei zum Schreiben *bevor* `sudo` überhaupt greift, `tee`
umgeht das, weil es selbst mit erhöhten Rechten läuft.

Im Browser: `http://<ip-deiner-vm>/info.php` — du solltest eine ausführliche PHP-Konfigurationsseite sehen
(PHP-Version, geladene Module, `php.ini`-Pfad usw.). Wenn stattdessen der **PHP-Quellcode als Text**
angezeigt wird (`<?php phpinfo();` im Klartext), hat Apache die Datei nicht an PHP weitergereicht — dann
zurück zu Schritt 2.

**Wichtig — danach wieder löschen:**

```bash
sudo rm /var/www/html/info.php
```

`phpinfo()` zeigt sehr viele interne Server-Details (Pfade, geladene Module, teils Umgebungsvariablen) —
das sollte niemals dauerhaft öffentlich erreichbar sein.

## Verifikation über die Kommandozeile

```bash
php -v                        # installierte PHP-Version
php -m                        # alle aktiven Erweiterungen
php -m | grep -Ei 'pgsql|gd|curl|mbstring|xml|zip|ldap|json'
```

Jede der gesuchten Erweiterungen sollte in der Ausgabe erscheinen.

## Was du gelernt hast

- PHP wird bei `mod_php` direkt im Apache-Prozess ausgeführt (daher die MPM-Kopplung aus Kapitel 2).
- Funktionalität kommt über gezielt installierte Erweiterungen (`php-pgsql`, `php-gd`, ...), nicht "aus dem
  Kern".
- `phpinfo()` ist ein nützliches, aber sicherheitsrelevantes Diagnosewerkzeug — nur temporär einsetzen.
- `echo ... | sudo tee datei` ist der Standardweg, um mit erhöhten Rechten in eine Datei zu schreiben, wenn
  eine einfache Shell-Umleitung (`>`) an fehlenden Rechten scheitern würde.

## Verständnis-Check

1. Was würdest du im Browser sehen, wenn `mod_php` nicht aktiv ist, du aber trotzdem `info.php` aufrufst?
2. Warum reicht `echo '...' > /var/www/html/info.php` (ohne `tee`) mit vorangestelltem `sudo` oft nicht aus?
3. Warum sollte `info.php` nicht dauerhaft auf dem Server bleiben?

Weiter mit [Kapitel 4: PostgreSQL von Hand einrichten](04-postgresql.md).
