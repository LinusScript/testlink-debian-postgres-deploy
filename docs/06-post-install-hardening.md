# 06 – Absichern nach der Installation

Nach einer erfolgreichen Installation solltest du folgende Punkte abarbeiten — auch (gerade) für eine Demo,
weil du diese Schritte später 1:1 für Prod übernimmst.

## 1. Installer-Verzeichnis sperren

Das `install/`-Verzeichnis bleibt sonst dauerhaft erreichbar und könnte theoretisch erneut aufgerufen werden
und die Datenbank überschreiben. `scripts/99-lock-installer.sh` benennt `install/` in `install.DISABLED/` um
(reversibel, falls du z. B. für ein Upgrade später wieder rein musst).

```bash
sudo ./scripts/99-lock-installer.sh
```

## 2. Schreibrechte einschränken

Nach der Installation braucht Apache nicht mehr auf den gesamten Baum Schreibzugriff — nur noch auf:

- `upload_area/`
- `gui/templates_c/`
- `logs/`

```bash
sudo find /var/www/testlink -type d -exec chmod 755 {} \;
sudo find /var/www/testlink -type f -exec chmod 644 {} \;
sudo chown -R www-data:www-data /var/www/testlink/upload_area /var/www/testlink/gui/templates_c /var/www/testlink/logs
```

## 3. `config_db.inc.php` schützen

Diese Datei enthält das Klartext-Passwort des `tl_login`-DB-Users:

```bash
sudo chmod 640 /var/www/testlink/config_db.inc.php
sudo chown www-data:www-data /var/www/testlink/config_db.inc.php
```

## 4. HTTPS aktivieren

Für eine Demo mit echter Domain (kein `.local`) lohnt sich sofort Let's Encrypt via `certbot`:

```bash
sudo apt-get install -y certbot python3-certbot-apache
sudo certbot --apache -d <TL_DOMAIN>
```

## 5. PostgreSQL-Superuser-Passwort danach nicht mehr für den täglichen Betrieb nutzen

TestLink läuft ab jetzt mit dem eingeschränkten `tl_login`-User (siehe `config_db.inc.php`). Das
`postgres`-Superuser-Passwort brauchst du nur noch für Wartung/Backups — nicht in weitere Konfigurationen
eintragen.

Weiter mit [`07-production-notes.md`](07-production-notes.md), wenn du diesen Aufbau produktiv nachbauen willst.
