# 5 – Häufige Alltagsprobleme

## Ziel dieses Kapitels

Konkrete Probleme, die typischerweise **nach** einer erfolgreichen Installation auftreten — im
laufenden Betrieb, Wochen oder Monate später. Für Fehler **während** der Installation/Migration siehe
[`installation/08`](../installation/08-verification-debugging.md) statt hier.

## „TestLink wird langsam"

Kein spezifischer Fehler, sondern ein Symptom — die Ursache eingrenzen mit dem Werkzeug aus
[Kapitel 3](03-performance-monitoring.md):

1. `htop`/`uptime` — ist die CPU/Load grundsätzlich hoch?
2. `SELECT count(*) FROM pg_stat_activity;` — ist die DB-Verbindungsgrenze fast erreicht?
3. `apache2ctl status` — sind alle Apache-Worker belegt?
4. `df -h` — ist die Festplatte fast voll? (Ein volles Dateisystem verlangsamt praktisch alles, auch
   scheinbar unabhängige Vorgänge.)

## „Festplatte wird knapp, obwohl niemand große Dateien hochlädt"

Häufigster Übeltäter: **alte Backups**, die sich unbemerkt ansammeln (siehe
[Kapitel 2](02-backup-restore.md) — `KEEP_DAYS` prüfen), oder Log-Dateien
(`/var/log/apache2/`, `TL_INSTALL_DIR/logs/`), die nie rotiert wurden:

```bash
du -sh /var/backups/testlink-postgres/*
du -sh /var/log/apache2/*
```

Für Logs: `logrotate` ist auf Debian meist schon vorinstalliert und für Apache vorkonfiguriert — prüfen
mit `cat /etc/logrotate.d/apache2`.

## „PostgreSQL wird langsamer, obwohl die Datenmenge kaum gewachsen ist"

PostgreSQL markiert gelöschte/geänderte Zeilen zunächst nur als ungültig, statt sie sofort physisch zu
entfernen (Grund: MVCC — mehrere gleichzeitige Lesevorgänge sollen nicht blockiert werden). Ohne
Aufräumen wächst die Tabelle intern trotzdem ("Bloat"). Abhilfe:

```sql
VACUUM ANALYZE;
```

Läuft auf modernen PostgreSQL-Versionen standardmäßig automatisch im Hintergrund (`autovacuum`) — bei
spürbaren Problemen trotzdem manuell prüfen:

```sql
SHOW autovacuum;
```

## „Ein Testfall/Projekt wurde versehentlich gelöscht"

TestLink hat keinen "Papierkorb" für gelöschte Inhalte — die einzige Wiederherstellungsmöglichkeit ist
ein **Restore aus dem Backup** (siehe [Kapitel 2](02-backup-restore.md)). Das ist der stärkste Grund,
warum regelmäßige, **getestete** Backups keine Kür, sondern Pflicht sind.

## „E-Mail-Benachrichtigungen (z. B. bei Testfall-Zuweisung) kommen nicht an"

TestLink verschickt Mails über einen konfigurierten SMTP-Server — das steht in
`custom_config.inc.php` (siehe [`grundlagen/testlink.md`](../grundlagen/testlink.md) für die
Dateiübersicht), nicht in `config_db.inc.php`. Prüfen:

1. Ist überhaupt ein SMTP-Server in `custom_config.inc.php` eingetragen?
2. Erlaubt die Firewall des Servers ausgehende Verbindungen auf dem SMTP-Port?
3. Apache-Fehlerlog prüfen (siehe [`installation/08`](../installation/08-verification-debugging.md)) —
   Mail-Fehler landen meist dort.

## „Ein Nutzer hat sein Passwort vergessen"

Als System-Administrator: **Benutzerverwaltung** öffnen (siehe
[Kapitel 1](01-user-management.md)), Benutzer auswählen, neues Passwort setzen. Kein Zugriff auf die
Datenbank nötig — das ist reine Anwendungsfunktion.

## Wann reicht dieses Kapitel nicht mehr aus?

Diese Liste deckt die häufigsten Fälle ab, ist aber keine vollständige Fehlerdatenbank. Bei neuen,
wiederkehrenden Problemen: notiere dir Symptom + Ursache + Lösung selbst (z. B. in einer eigenen Notiz
oder direkt als Ergänzung zu diesem Kapitel) — genau das macht dich mit der Zeit zur Person, die diese
Fragen beantworten kann, statt sie erneut zu recherchieren.

## Was du gelernt hast

- TestLink hat keinen Papierkorb — gelöschte Inhalte sind nur über ein Backup wiederherstellbar.
- PostgreSQL braucht gelegentliches Aufräumen (VACUUM) wegen seines MVCC-Modells, meist automatisch,
  aber prüfbar.
- Mail-Probleme liegen fast immer an `custom_config.inc.php` oder der Firewall, nicht an TestLink selbst.
- Passwort-Resets sind eine reine Anwendungsfunktion, keine Datenbankoperation.

## Verständnis-Check

1. Warum kann man einen versehentlich gelöschten Testfall nicht einfach "wiederherstellen" wie eine
   Datei im Papierkorb?
2. Was bedeutet MVCC, und warum führt es dazu, dass PostgreSQL gelegentlich aufgeräumt werden muss?
3. Ein Kollege bekommt keine E-Mail-Benachrichtigung von TestLink. In welcher Datei suchst du zuerst?
