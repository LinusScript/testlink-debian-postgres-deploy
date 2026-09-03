# 9 – Absichern & Brücke zu Prod

## Ziel dieses Kapitels

Du verstehst, welche Schritte nach einer erfolgreichen Installation zwingend sind (auch für eine Demo),
und welche Punkte sich ändern, wenn du dieselbe Anleitung später auf einem echten Produktivserver
durchgehst.

## Schritt 1: Installer-Verzeichnis sperren

`install/` bleibt nach der Installation dauerhaft erreichbar. Ruft jemand die Seiten erneut auf, könnte er
theoretisch versuchen, die bestehende Datenbank zu überschreiben. Da wir den Installer nicht mehr brauchen,
sperren wir ihn — reversibel, falls du für ein späteres Upgrade nochmal rein musst:

```bash
sudo mv /var/www/testlink/install /var/www/testlink/install.DISABLED
```

**Warum umbenennen statt löschen?** Ein Upgrade auf eine neuere TestLink-Version nutzt teilweise dieselben
Installer-Skripte für Datenbank-Migrationen (`install/sql/alter_tables/`). Löschen würde diesen Weg
verbauen; Umbenennen macht das Verzeichnis für Außenstehende unerreichbar, du kannst es aber selbst jederzeit
zurückbenennen.

## Schritt 2: Schreibrechte nach der Installation einschränken

Während der Installation musste `www-data` auf das **gesamte** Verzeichnis schreiben können. Im laufenden
Betrieb braucht Apache/PHP das nur noch für drei Unterverzeichnisse:

```bash
sudo find /var/www/testlink -type d -exec chmod 755 {} \;
sudo find /var/www/testlink -type f -exec chmod 644 {} \;
sudo chown -R www-data:www-data \
  /var/www/testlink/upload_area \
  /var/www/testlink/gui/templates_c \
  /var/www/testlink/logs
```

Das ist das **Prinzip der geringsten Rechte** wieder auf Dateisystem-Ebene angewendet (dasselbe Prinzip,
das dich in Kapitel 7 dazu gebracht hat, TestLink mit dem eingeschränkten `tl_login`-DB-User statt dem
Superuser laufen zu lassen).

## Schritt 3: `config_db.inc.php` zusätzlich schützen

Diese Datei enthält das Klartext-Passwort des `tl_login`-DB-Users:

```bash
sudo chmod 640 /var/www/testlink/config_db.inc.php
sudo chown www-data:www-data /var/www/testlink/config_db.inc.php
```

`640` = Besitzer (`www-data`) liest+schreibt, Gruppe (`www-data`) liest nur, alle anderen: gar nichts.

## Schritt 4: HTTPS (nur sinnvoll mit echter Domain)

Mit einer echten, öffentlich auflösbaren Domain (nicht `.local`) kannst du kostenlos ein
Let's-Encrypt-Zertifikat einrichten:

```bash
sudo apt-get install -y certbot python3-certbot-apache
sudo certbot --apache -d deine-domain.de
```

`certbot` erweitert dabei automatisch deine `testlink.conf` um einen `<VirtualHost *:443>`-Block mit
Zertifikat und richtet i. d. R. auch eine automatische HTTP→HTTPS-Weiterleitung ein — schau danach mit
`sudo apache2ctl -S` und einem Blick in `testlink.conf`, was sich geändert hat (guter Anlass, das VirtualHost-
Wissen aus Kapitel 6 anzuwenden).

## Die eigentliche Brücke: Was ändert sich für Prod, was bleibt gleich?

| Bereich | Demo (dieser Lernpfad) | Prod — was du änderst |
|---|---|---|
| **Ablauf der Schritte** | Kapitel 0–9 | **Identisch** — das ist der ganze Sinn dieser Anleitung |
| **Passwörter** | einfach, für dich merkbar | eigene, starke, in einem Passwortmanager/Secret-Store, **nicht wiederverwendet** |
| **Domain** | `.local` oder IP | echte, öffentlich auflösbare Domain |
| **TLS** | optional/keins | Pflicht (Schritt 4 oben) |
| **PostgreSQL-Standort** | lokal auf demselben Server | ggf. eigener DB-Server/Managed-DB — dann `PG_HOST` in Kapitel 4/7 auf dessen Adresse setzen, `pg_hba.conf` auf die **IP des Webservers** statt `127.0.0.1` erweitern, `listen_addresses` im `postgresql.conf` entsprechend anpassen |
| **Backups** | keine | `pg_dump` regelmäßig (Cron/systemd-Timer) + `upload_area/` sichern (dort liegen Anhänge, die **nicht** in der Datenbank stehen) |
| **Updates** | manuell bei Bedarf | eingeplant: `apt-get update && upgrade` für System/PHP/PostgreSQL, TestLink-Releasenotes für Anwendungs-Updates |
| **Monitoring** | keins | mindestens Log-Überwachung, im Idealfall Uptime-/Metrik-Monitoring |
| **PHP-Ausführung** | `mod_php` + MPM `prefork` (Kapitel 2/3) | bei höherer Last: PHP-FPM + MPM `event` (mehr Durchsatz, sauberere Prozesstrennung) |

## PHP-FPM als Prod-Option (nur zum Verständnis, hier nicht ausgeführt)

Der Vollständigkeit halber, falls du später mit einem Kollegen/Ausbilder darüber sprichst: PHP-FPM
(**F**astCGI **P**rocess **M**anager) betreibt PHP als **eigenständigen Prozess-Pool**, getrennt von Apache.
Apache reicht Anfragen über das FastCGI-Protokoll an diesen Pool weiter (`mod_proxy_fcgi`), statt PHP direkt
in seine eigenen Worker einzubetten. Vorteil: Apache kann dabei beim schnelleren `event`-MPM bleiben (siehe
Kapitel 2), und PHP-Prozesse lassen sich unabhängig von Apache skalieren/neu starten. Nachteil: eine
bewegliche Komponente mehr, etwas komplexeres Debugging (zwei Prozesse statt einem). Für den Einstieg und
diesen Lernpfad ist `mod_php` bewusst die einfachere Wahl. Konkrete Umstellungsschritte (inklusive
Connection Pooling für PostgreSQL) stehen in
[`grundlagen/performance-tuning.md`](../grundlagen/performance-tuning.md), für den Zeitpunkt, an dem es
sich wirklich lohnt.

## Zusammenfassung: Reproduzierbarkeit als Ziel

Der Kern dieser gesamten Anleitung: **Jeder Schritt hier ist bewusst so geschrieben, dass du ihn 1:1 auf
einem anderen Server wiederholen kannst** — nur mit anderen Werten für Domain, Passwörter und ggf.
DB-Host. Genau deswegen lohnt es sich, jetzt zu verstehen, statt nur die `scripts/*.sh`-Dateien blind
laufen zu lassen: Wenn in Prod etwas anders reagiert als in der Demo, weißt du durch dieses Verständnis, in
welcher Schicht (Kapitel 8) du suchen musst.

## Verständnis-Check (Gesamtwiederholung)

1. Erkläre in eigenen Worten den kompletten Weg einer Anfrage von deinem Browser bis zur PostgreSQL-Antwort
   und zurück — nenne jede beteiligte Komponente.
2. Warum reicht es nicht, `pg_hba.conf` einmal richtig einzustellen — was musst du zusätzlich tun, damit
   die Änderung wirkt?
3. Nenne zwei Gründe, warum TestLink mit einem eingeschränkten `tl_login`-DB-User läuft statt mit dem
   `postgres`-Superuser.
4. Was änderst du konkret, wenn PostgreSQL künftig auf einem separaten Server statt lokal läuft?

**Geschafft!** Du hast den kompletten Stack von der Proxmox-VM bis zur laufenden, abgesicherten
TestLink-Installation manuell aufgebaut und verstanden. Die `scripts/*.sh` im Hauptverzeichnis bilden jetzt
genau das ab, was du hier von Hand gemacht hast — lies sie dir einmal durch, du solltest jede Zeile
wiedererkennen.
