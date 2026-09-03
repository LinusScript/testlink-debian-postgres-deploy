# 3 – Performance & Monitoring

## Ziel dieses Kapitels

Wissen, **worauf** du im laufenden Betrieb regelmäßig achten solltest, bevor ein Problem für die Nutzer
sichtbar wird — und die Werkzeuge dafür kennen. Für die tiefere Frage "wie stelle ich PHP/Apache/
PostgreSQL um, wenn die Last wirklich steigt" siehe
[`grundlagen/performance-tuning.md`](../grundlagen/performance-tuning.md).

## Die vier Dinge, die am ehesten knapp werden

| Ressource | Warum sie TestLink konkret betrifft | Womit prüfen |
|---|---|---|
| **Festplattenspeicher** | `upload_area/` wächst mit jedem Anhang, `pg_dump`-Backups sammeln sich, PostgreSQL selbst wächst mit den Daten | `df -h` |
| **PostgreSQL-Verbindungen** | Jeder gleichzeitige Nutzer/Prozess kann eine DB-Verbindung belegen — ein Standard-Limit ist schneller erreicht, als man denkt | `SELECT count(*) FROM pg_stat_activity;` |
| **Apache-Worker (bei `mod_php`+`prefork`)** | Jeder gleichzeitige Request bindet einen kompletten Prozess (siehe [`grundlagen/apache.md`](../grundlagen/apache.md)) | `apache2ctl status` (mit `mod_status`) |
| **CPU/RAM allgemein** | Zeigt grundsätzliche Überlastung, unabhängig von der Ursache | `top`/`htop` |

## Praktisch: Festplattenspeicher prüfen

```bash
df -h /var/www /var/lib/postgresql /var/backups
du -sh /var/www/testlink/upload_area
```

**Faustregel:** Handle spätestens bei 80 % Auslastung, nicht erst bei 95 % — PostgreSQL kann bei vollem
Datenträger beschädigt werden, weil laufende Schreibvorgänge nicht sauber abgeschlossen werden können.

## Praktisch: PostgreSQL-Verbindungen im Blick behalten

```sql
-- Wie viele Verbindungen sind aktuell offen?
SELECT count(*) FROM pg_stat_activity;

-- Wie hoch ist das konfigurierte Limit?
SHOW max_connections;

-- Welche Verbindungen sind seit langem "idle in transaction" (oft ein Zeichen für ein Problem im Code/Skript)?
SELECT pid, usename, state, now() - query_start AS duration
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY duration DESC;
```

Nähert sich `count(*)` dem `max_connections`-Limit dauerhaft, ist das ein Signal — entweder für echtes
Wachstum (mehr Nutzer) oder für einen Fehler, bei dem Verbindungen nicht sauber geschlossen werden.

## Praktisch: Apache-Auslastung prüfen

```bash
sudo a2enmod status
sudo systemctl reload apache2
curl http://localhost/server-status
```

Zeigt aktive/wartende Worker-Prozesse. Bei `mod_php` + `prefork` (unser Setup, siehe
[`grundlagen/apache.md`](../grundlagen/apache.md)) ist jeder Worker ein vollständiger Prozess — läuft
`MaxRequestWorkers` (die maximale Prozessanzahl) regelmäßig voll, warten neue Anfragen, bis ein Worker
frei wird — spürbar als "TestLink wird langsam".

## Praktisch: Allgemeine Systemlast

```bash
htop        # interaktiv, übersichtlicher als top
uptime      # Load Average — grob: Wert dauerhaft über der Anzahl CPU-Kerne = überlastet
```

## Wann reicht "gelegentlich draufschauen" nicht mehr?

Für eine kleine, einzelne TestLink-Instanz ist regelmäßiges manuelles Prüfen (z. B. wöchentlich, plus
gezielt bei gemeldeter Langsamkeit) ein vertretbarer Einstieg. Sobald mehrere Teams/viele gleichzeitige
Nutzer dazukommen, lohnt sich echtes Monitoring mit Verlauf und Alarmierung (z. B. Prometheus + Grafana,
oder einfacher: ein Cronjob, der die obigen Werte protokolliert und bei Überschreitung eine Mail
schickt) — das ist bewusst nicht Teil dieses Repos, aber der nächste logische Schritt, sobald die
Instanz wichtig genug wird.

## Was du gelernt hast

- Die vier Engpässe, die bei TestLink typischerweise zuerst auftreten: Speicherplatz,
  DB-Verbindungen, Apache-Worker, allgemeine Systemlast.
- `pg_stat_activity` zeigt dir PostgreSQLs aktuelle Verbindungen live — inklusive verdächtiger
  "idle in transaction"-Zustände.
- Bei `mod_php`+`prefork` ist die Anzahl gleichzeitiger Apache-Worker ein harter, spürbarer Engpass.
- Manuelles, regelmäßiges Prüfen reicht für eine kleine Instanz; ab einer gewissen Größe braucht es
  echtes Monitoring mit Verlauf und Alarmierung.

## Verständnis-Check

1. Warum ist volle Festplatte für PostgreSQL gefährlicher als für die meisten anderen Anwendungen?
2. Was bedeutet ein dauerhaft hoher Wert bei "idle in transaction" in `pg_stat_activity`?
3. Warum ist die Anzahl gleichzeitiger Apache-Worker bei `mod_php`+`prefork` ein härterer Engpass als
   bei PHP-FPM?

Weiter mit [Kapitel 4: Upgrade-Strategie](04-upgrade-strategy.md).
