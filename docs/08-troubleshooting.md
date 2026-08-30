# 08 – Troubleshooting

## „Failed! ... pgsql cannot be used" im Installer-Systemcheck

Die PHP-Erweiterung `pgsql` fehlt oder ist nicht aktiviert.

```bash
sudo apt-get install -y php-pgsql
sudo systemctl restart apache2
php -m | grep pgsql
```

## Weiße Seite / Fatal Error nach dem Öffnen von TestLink

Meist ein PHP-8-Kompatibilitätsproblem (z. B. bei Verwendung des alten offiziellen Tags `1.9.20` statt
`1.9.20-20251208`). Prüfen:

```bash
tail -n 50 /var/log/apache2/error.log
```

Falls dort Fehler zu entfernten PHP-Funktionen auftauchen (z. B. `create_function`, dynamische Properties),
sicherstellen, dass `TL_VERSION=1.9.20-20251208` (oder neuer) in `.env` gesetzt war, bevor
`04-deploy-testlink.sh` lief, und ggf. mit dem korrekten Tag neu deployen.

## „Could not create database" / „Could not create user" im Web-Installer

- PostgreSQL-Verbindung testen: `psql -h 127.0.0.1 -U postgres -c '\conninfo'` (Passwort = `PG_SUPERUSER_PASSWORD`)
- Stimmt das im Installer eingegebene Administrator-Passwort mit dem in `.env` gesetzten überein?
- Läuft PostgreSQL überhaupt? `systemctl status postgresql`
- `pg_hba.conf` prüfen: gibt es eine `host ... 127.0.0.1/32 scram-sha-256` (oder `md5`) Zeile?
  (`scripts/03-install-postgresql.sh` sollte das automatisch sichergestellt haben.)

## Apache zeigt „It works!" oder Debian-Default-Seite statt TestLink

Der VirtualHost wurde nicht aktiviert oder `TL_DOMAIN`/Port stimmen nicht mit dem Aufruf überein.

```bash
sudo apache2ctl -S          # zeigt aktive VirtualHosts
sudo a2ensite testlink.conf
sudo systemctl reload apache2
```

## „Permission denied" beim Schreiben von `config_db.inc.php` während der Installation

`www-data` hat keinen Schreibzugriff auf das Zielverzeichnis. Kontrolle:

```bash
ls -la /var/www/testlink | head
sudo chown -R www-data:www-data /var/www/testlink
```

## Diagramme/Charts werden nicht angezeigt

`gd`-Extension fehlt — nicht kritisch für den Betrieb, nur für Report-Grafiken:

```bash
sudo apt-get install -y php-gd
sudo systemctl restart apache2
```

## Ich will die Installation komplett neu starten

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
4. Web-Installer erneut aufrufen (siehe [`05-web-installer-walkthrough.md`](05-web-installer-walkthrough.md)).
