# 02 – Apache & PHP installieren

## Was TestLink an PHP-Erweiterungen braucht

TestLink prüft seine Umgebung selbst beim ersten Aufruf des Web-Installers (`install/installCheck.php`
→ `lib/functions/configCheck.php`). Aus dem Quellcode (Tag `1.9.20-20251208`) ergeben sich folgende
Anforderungen:

- **PHP >= 7.4.2** (Debian Trixie liefert 8.4 — läuft laut Changelog des gewählten Tags)
- **`pgsql`** – Pflicht, da wir PostgreSQL verwenden
- **`gd`** – für Diagramme/Grafiken (Report-Charts); ohne läuft TestLink, aber ohne Diagramme
- **`json`**, **`curl`** – Pflicht laut Installer-Check (REST-Integration, EXT-JS-Baumkomponente)
- **`ldap`** – optional, nur für LDAP-Login nötig
- zusätzlich empfohlen (von Smarty-Templating/Composer-Abhängigkeiten im Code verwendet, auch wenn der
  Installer sie nicht explizit prüft): **`mbstring`**, **`xml`**, **`zip`**

> Der Web-Installer zeigt dir auf der ersten Seite (`install/installCheck.php`) eine Live-Übersicht aller
> Checks. Falls dort trotz dieser Anleitung etwas rot/gelb markiert ist, installiere das fehlende Paket und
> lade die Seite neu — das ist die zuverlässigste Quelle, nicht diese Liste.

## Warum mod_php + MPM prefork statt PHP-FPM?

Apache auf Debian nutzt standardmäßig den asynchronen **MPM `event`**, der mit klassischem `mod_php` nicht
kompatibel ist. TestLink ist als klassische mod_php-Anwendung geschrieben. Der einfachste, am wenigsten
fehleranfällige Weg für eine Demo ist daher, auf **MPM `prefork`** zu wechseln und `mod_php` zu nutzen.
(Produktiv-Alternative mit PHP-FPM siehe [`07-production-notes.md`](07-production-notes.md).)

## Was `scripts/02-install-apache-php.sh` macht

1. Installiert `apache2`
2. Deaktiviert `mpm_event`, aktiviert `mpm_prefork`
3. Installiert `php` (→ PHP 8.4 auf Trixie) sowie:
   `libapache2-mod-php php-pgsql php-gd php-curl php-mbstring php-xml php-zip php-ldap`
4. Aktiviert die nötigen Apache-Module (`php`, `rewrite`)
5. Startet Apache neu und zeigt PHP-/Apache-Version zur Kontrolle an

Ausführen:

```bash
sudo ./scripts/02-install-apache-php.sh
```

## Manuelle Kontrolle

```bash
php -v
apache2 -v
php -m | grep -Ei 'pgsql|gd|curl|mbstring|xml|zip|ldap|json'
```
