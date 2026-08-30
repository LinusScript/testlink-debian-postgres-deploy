# 07 – Hinweise für den Produktivbetrieb

Dieses Repo ist so gebaut, dass der gleiche Ablauf (`01` → `06`) 1:1 auf einem Produktivserver wiederholbar
ist — mit eigener `.env` und eigenen Passwörtern. Zusätzlich für Prod relevant:

## Getrennte Datenbank

Für eine Demo läuft PostgreSQL lokal auf demselben Server (`PG_HOST=127.0.0.1`). Für Prod ist ein separater
Datenbankserver/-dienst (eigene VM, Managed-PostgreSQL) empfehlenswert:

- `PG_HOST` in `.env` auf den DB-Host setzen.
- In `pg_hba.conf` auf dem DB-Server die IP des Webservers statt `127.0.0.1` freigeben.
- `listen_addresses` im `postgresql.conf` des DB-Servers auf die private Netzwerkschnittstelle setzen
  (nicht `*`, außer eine Firewall schützt zusätzlich).
- Verbindung nach Möglichkeit über ein privates Netzwerk/VPN statt öffentliches Internet.

## Backups

- **Datenbank**: `pg_dump` regelmäßig (z. B. via `systemd`-Timer oder Cronjob), Dumps extern lagern.
- **Dateisystem**: mindestens `upload_area/` (Anhänge/Uploads) sichern — diese Daten stehen nicht in der DB.

## TLS/Domain

- Echte Domain statt `.local` verwenden, `certbot --apache` für Let's-Encrypt-Zertifikat (siehe
  [`06-post-install-hardening.md`](06-post-install-hardening.md)).
- Erwäge eine Weiterleitung HTTP → HTTPS (macht `certbot --apache` bei entsprechender Nachfrage automatisch).

## PHP-FPM statt mod_php (optional, für mehr Last)

Die Demo nutzt `mod_php` + MPM `prefork`, weil das am nächsten am klassischen TestLink-Setup ist. Für höhere
Last skaliert PHP-FPM mit Apache-MPM `event` besser:

```bash
sudo apt-get install -y php-fpm libapache2-mod-fcgid
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php*-fpm
sudo a2dismod php* mpm_prefork
sudo a2enmod mpm_event
sudo systemctl restart apache2 php*-fpm
```

(Danach die VirtualHost-Konfiguration entsprechend auf FPM umstellen — nicht Teil der Demo-Skripte hier.)

## Updates

- TestLink-Updates: neuen Tag laden, Dateien austauschen (**außer** `config_db.inc.php`,
  `custom_config.inc.php`, `upload_area/`), SQL-Migrationsskripte aus `install/sql/alter_tables/` gemäß
  offizieller Release-Notes ausführen.
- Debian/PHP/PostgreSQL-Sicherheitsupdates: `apt-get update && apt-get upgrade` regelmäßig einplanen
  (z. B. `unattended-upgrades`).

## Monitoring/Logs

- Apache-Logs: `/var/log/apache2/`
- TestLink-eigene Logs: `TL_INSTALL_DIR/logs/`
- PostgreSQL-Logs: `/var/log/postgresql/`

## Zugangsdaten

Alle in `.env` verwendeten Passwörter (`PG_SUPERUSER_PASSWORD`, `TL_DB_PASSWORD`) sollten für Prod
eigenständig, stark und in einem Passwortmanager/Secret-Store verwaltet werden — **nicht** die Demo-Werte
wiederverwenden.
