# 04 – TestLink deployen

## Was `scripts/04-deploy-testlink.sh` macht

1. Lädt den TestLink-Quellcode für den in `.env` konfigurierten Tag (`TL_VERSION`, Default
   `1.9.20-20251208`) direkt von GitHub als Tarball:
   ```
   https://github.com/TestLinkOpenSourceTRMS/testlink-code/archive/refs/tags/<TL_VERSION>.tar.gz
   ```
2. Entpackt ihn nach `TL_INSTALL_DIR` (Default `/var/www/testlink`).
3. Setzt den Besitzer rekursiv auf `www-data:www-data`, damit Apache/PHP schreiben kann (nötig für den
   Installer, für `upload_area/`, `logs/`, `gui/templates_c/`).
4. Legt einen Apache-VirtualHost für `TL_DOMAIN`/`TL_HTTP_PORT` an, der als DocumentRoot auf
   `TL_INSTALL_DIR` zeigt, aktiviert die Seite und lädt Apache neu.

Ausführen:

```bash
sudo ./scripts/04-deploy-testlink.sh
```

## Warum `www-data:www-data` auf das gesamte Verzeichnis?

Der Web-Installer schreibt beim Durchlaufen selbst Dateien (u. a. `config_db.inc.php`), und TestLink legt
zur Laufzeit Uploads (`upload_area/`) und kompilierte Templates (`gui/templates_c/`) an. Für eine Demo ist
"alles gehört www-data" der pragmatischste Weg. Für Produktiv-Härtung siehe
[`06-post-install-hardening.md`](06-post-install-hardening.md) — dort wird der Schreibzugriff nach der
Installation wieder eingeschränkt.

## Manuelle Kontrolle

```bash
ls -la /var/www/testlink | head
curl -I http://<TL_DOMAIN oder Server-IP>/
```

Ein `200 OK` (oder eine Weiterleitung auf `install/`) zeigt, dass Apache den VirtualHost korrekt ausliefert.
Weiter geht's mit dem Browser-Installer in [`05-web-installer-walkthrough.md`](05-web-installer-walkthrough.md).
