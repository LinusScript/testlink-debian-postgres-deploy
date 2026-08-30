# 03 – PostgreSQL einrichten

## Was hier passiert (und was nicht)

Wie in [`00-overview.md`](00-overview.md) beschrieben, legt **TestLink selbst** über den Web-Installer seine
Datenbank und seinen eigenen DB-User an. Dieser Schritt hier muss daher nur:

1. PostgreSQL installieren,
2. dem Superuser `postgres` ein Passwort geben (standardmäßig ist er nur per `peer`-Auth über den
   Unix-Socket ansprechbar, nicht per Passwort),
3. sicherstellen, dass Passwort-Login per TCP auf `127.0.0.1` erlaubt ist — das ist bei einer frischen
   Debian-Installation von PostgreSQL bereits per Default so konfiguriert (`pg_hba.conf` enthält standardmäßig
   `host all all 127.0.0.1/32 scram-sha-256`), das Skript prüft/ergänzt das aber zur Sicherheit.

Es wird **keine** `testlink`-Datenbank und **kein** `tl_login`-User von Hand angelegt — das übernimmt der
Web-Installer in Schritt 5.

## Was `scripts/03-install-postgresql.sh` macht

1. Installiert `postgresql postgresql-contrib`
2. Setzt das Passwort des Superusers `postgres` auf `PG_SUPERUSER_PASSWORD` aus `.env`:
   ```sql
   ALTER USER postgres WITH PASSWORD '...';
   ```
3. Prüft `pg_hba.conf` auf eine Zeile für TCP-Passwort-Login von `127.0.0.1`/`::1` und ergänzt sie, falls sie
   fehlt.
4. Prüft `postgresql.conf` auf `listen_addresses` (muss mindestens `localhost` enthalten).
5. Startet den `postgresql`-Dienst neu.

Ausführen:

```bash
sudo ./scripts/03-install-postgresql.sh
```

## Manuelle Kontrolle

```bash
# Verbindung per TCP mit Passwort testen (Passwort aus .env eingeben)
psql -h 127.0.0.1 -U postgres -c '\conninfo'
```

Wenn das ohne Fehler ein `\conninfo`-Ergebnis liefert, ist PostgreSQL bereit für den TestLink-Web-Installer.

## Sicherheitshinweis

`postgres` ist der Datenbank-Superuser. Das hier vergebene Passwort brauchst du **nur einmalig** im
Web-Installer (Schritt 5). Danach arbeitet TestLink mit dem eigens angelegten, eingeschränkten
`tl_login`-User. Bewahre `PG_SUPERUSER_PASSWORD` trotzdem sicher auf (Passwortmanager) — für Backups/
Wartung brauchst du ihn wieder.
