# 01 – Server-Vorbereitung

## Voraussetzungen

- Ein Debian-13-Server ("Trixie") mit root- bzw. sudo-Zugriff (frisch installiert oder eine leere VM/vServer).
- Mindestens 1 vCPU / 1 GB RAM für eine Demo (TestLink selbst ist genügsam; PostgreSQL + Apache + PHP
  laufen damit problemlos).
- SSH-Zugriff auf den Server.
- Eine Domain oder zumindest die IP-Adresse, unter der du TestLink später aufrufen willst.

## Repo auf den Server holen

```bash
sudo apt-get update && sudo apt-get install -y git
git clone <URL-dieses-Repos> testlink-deploy
cd testlink-deploy
cp .env.example .env
```

Öffne `.env` und passe mindestens folgende Werte an, **bevor** du irgendein Skript ausführst:

- `PG_SUPERUSER_PASSWORD` – starkes, eigenes Passwort
- `TL_DB_PASSWORD` – starkes, eigenes Passwort (nur als Notiz für den Web-Installer, siehe Schritt 5)
- `TL_DOMAIN` – deine Domain/IP
- optional `TL_VERSION`, `TL_INSTALL_DIR`, `TL_HTTP_PORT`

## Was `scripts/01-prepare-system.sh` macht

- `apt-get update && apt-get upgrade -y` — System auf aktuellen Stand bringen
- Installiert Basis-Werkzeuge: `curl`, `wget`, `ca-certificates`, `gnupg`, `unzip`, `tar`
- Prüft, dass das Skript als root läuft (`sudo`)

Ausführen:

```bash
sudo ./scripts/01-prepare-system.sh
```

Das Skript ist idempotent — mehrfaches Ausführen schadet nicht (nützlich, wenn du es später auf dem
Produktivserver wiederholst).
