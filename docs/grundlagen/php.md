# Was ist PHP?

## Kurzfassung

PHP ist eine **Programmiersprache**, die speziell dafür entwickelt wurde, auf einem Webserver zu laufen
und bei jeder Anfrage eine Webseite dynamisch zu erzeugen — die Sprache, in der TestLink komplett
geschrieben ist.

## Geschichte

PHP wurde 1994 von **Rasmus Lerdorf** entwickelt — ursprünglich gar nicht als Programmiersprache
gedacht, sondern als kleine Sammlung von C-Programmen, mit denen er nachverfolgen wollte, wie oft
Besucher seinen eigenen Lebenslauf online aufriefen. Er nannte die Sammlung **"Personal Home Page
Tools"** — daher der Name. 1995 veröffentlichte er den Quellcode, die Entwickler-Community griff das
Werkzeug auf, und mit Hilfe von **Andi Gutmans** und **Zeev Suraski** wurde daraus eine echte, allgemein
nutzbare Programmiersprache (PHP/FI, "Personal Home Page/Forms Interpreter"). Der Name blieb — heute
steht PHP als rekursives Backronym für **"PHP: Hypertext Preprocessor"**.

**Warum das für dich relevant ist:** PHP wurde von Anfang an für genau einen Zweck entworfen — Webseiten
dynamisch erzeugen — nicht als Allzweck-Sprache wie Python oder Java. Das erklärt, warum es so eng mit
Webservern wie Apache verzahnt ist (siehe [apache.md](apache.md)) und warum TestLink, wie die meisten
PHP-Anwendungen dieser Ära, direkt als Apache-Modul (`mod_php`) läuft, statt als eigenständiger,
unabhängiger Prozess.

## Kernkonzept: Serverseitige Ausführung

Der entscheidende Unterschied zu JavaScript im Browser: **PHP-Code läuft nicht bei dir**, sondern auf
dem Server, **bevor** die Seite bei dir im Browser ankommt.

```
Browser fragt "index.php" an
       ↓
Server (Apache) erkennt: das ist eine .php-Datei
       ↓
PHP-Interpreter führt den Code aus (liest z.B. Daten aus PostgreSQL,
verarbeitet sie, erzeugt HTML)
       ↓
Nur das fertige HTML geht zurück an den Browser
```

Der Nutzer sieht **nie** den PHP-Quellcode selbst — nur das Ergebnis. Das ist auch ein
Sicherheitsaspekt: Datenbank-Zugangsdaten, Geschäftslogik etc. bleiben serverseitig verborgen.

## Wofür wird es verwendet

Allgemein: PHP treibt einen sehr großen Teil des Webs an — u. a. WordPress (und damit einen enormen
Anteil aller Websites weltweit), viele klassische Web-Anwendungen aus den 2000er/2010er-Jahren, weil es
einfach zu erlernen und auf praktisch jedem Hosting-Angebot vorinstalliert war/ist.

In unserem Kontext: TestLink **ist** PHP-Code. Jede `.php`-Datei im TestLink-Verzeichnis (`gui/`, `lib/`,
`install/`, ...) wird beim Aufruf vom PHP-Interpreter ausgeführt.

## Wichtige Begriffe

- **Interpreter** — das Programm, das PHP-Code zur Laufzeit liest und ausführt (kein separater
  Kompilierschritt wie bei Java/C nötig).
- **Erweiterung/Extension** (z. B. `pgsql`, `gd`, `curl`) — zusätzliche Fähigkeiten, die PHP nicht "im
  Kern" mitbringt, sondern gezielt dazu installiert werden (siehe [Kapitel 3](../installation/03-php.md)).
- **`php.ini`** — die zentrale Konfigurationsdatei (Speicherlimits, Timeouts, welche Erweiterungen aktiv
  sind).
- **`mod_php`** — die Variante, bei der PHP direkt in den Apache-Prozess eingebettet läuft (unser
  Setup) — Alternative: **PHP-FPM**, ein eigenständiger PHP-Prozess-Pool (siehe
  [Kapitel 9](../installation/09-hardening-and-prod.md)).
- **Session** — ein Mechanismus, mit dem PHP sich zwischen mehreren Anfragen "merkt", wer eingeloggt
  ist (TestLinks Login basiert darauf).

## Die wichtigsten Befehle

```bash
php -v              # installierte PHP-Version anzeigen
php -m              # alle aktiven Erweiterungen auflisten
php -m | grep pgsql # prüfen, ob eine bestimmte Erweiterung aktiv ist
php -i              # sehr ausführliche Konfigurationsübersicht (Kommandozeilen-Variante von phpinfo())
```

Diese Befehle **lesen nur** — sie verändern nichts. Für Änderungen bearbeitest du `php.ini` bzw.
installierst/aktivierst Erweiterungen über `apt`/`a2enmod` (siehe Kapitel 3).

## Bezug zu unserem Projekt

- [Kapitel 3](../installation/03-php.md) — PHP installieren, Erweiterungen, warum welche
- [Kapitel 2](../installation/02-apache.md) — warum `mod_php` ein bestimmtes Apache-MPM erzwingt
- [Migrations-Kapitel 1](../migration/01-konzept.md) — warum die alte TestLink-Version (1.9.16) mit
  moderner PHP-Version (8.4) Probleme macht
