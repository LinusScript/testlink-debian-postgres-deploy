# 13 – Vollständigkeits-Check: die echte Produktivdatenbank sauber migrieren

## Ziel dieses Kapitels

[Kapitel 12](12-migration-schritt2-db-wechsel.md) hat dir gezeigt, **wie** `pgloader` MySQL nach
PostgreSQL überträgt — mit den synthetischen 1.9.16-Standarddaten aus dem TestLink-Repo. Dieses Kapitel
schließt die Lücke zwischen "Demo mit Testdaten" und "echte Produktivmigration": Was gehört bei
TestLink *wirklich alles* zu "den Daten", woher bekommst du den echten Dump, und wie stellst du fest,
dass **nichts** fehlt — nicht nur zwei Tabellen stichprobenartig, sondern lückenlos.

## Was „vollständig" bei TestLink konkret bedeutet

TestLinks Zustand verteilt sich auf **vier unterschiedliche Orte** — nur einer davon ist die Datenbank,
die `pgloader` migriert:

| Kategorie | Wo | Migriert `pgloader` das? |
|---|---|---|
| Tabellendaten (Projekte, Testfälle, Nutzer, Rechte, ...) | MySQL-Datenbank, ~58 Tabellen | ✅ Ja |
| **Datei-Anhänge** | ggf. `upload_area/` **auf der Festplatte**, außerhalb der DB | ❌ Nein |
| Eigene Konfiguration | `custom_config.inc.php` auf dem alten Server | ❌ Nein — ist Code, keine Daten |
| Sessions/Caches | temporär, `gui/templates_c/`, PHP-Sessions | Nicht nötig — wird neu erzeugt |

Die zweite Zeile ist der häufigste Stolperstein bei TestLink-Migrationen und wird gleich genauer erklärt.

## Kritischer Punkt: Wo liegen die Anhänge wirklich?

Ich habe das im TestLink-Quellcode nachgesehen (`config.inc.php`): Die Tabelle `attachments` hat **immer**
beide möglichen Spalten — `file_path` (Pfad-Referenz) **und** `content` (ein `LONGBLOB`-Feld für die
Datei selbst). Welche davon tatsächlich benutzt wird, entscheidet eine einzige Einstellung:

```php
/** the type of the repository can be database or filesystem
 * TL_REPOSITORY_TYPE_DB => database
 * TL_REPOSITORY_TYPE_FS => filesystem
 **/
$g_repositoryType = TL_REPOSITORY_TYPE_FS;   // <- das ist der Standardwert
```

**Standardmäßig** speichert TestLink Anhänge **im Dateisystem** (`upload_area/`), die Datenbank enthält
dann nur Metadaten + einen Pfad. Eine Installation kann das in `custom_config.inc.php` aber auf
Datenbank-Speicherung umstellen.

**Das musst du für eure Produktivinstanz herausfinden, bevor du migrierst** — frag entweder deinen
Kollegen (schnellster Weg), oder prüfe es direkt an der Datenbank selbst:

```sql
SELECT id, file_name, file_path, LENGTH(content) AS content_bytes
FROM attachments
LIMIT 10;
```

- **`content_bytes` ist `0`/`NULL`, `file_path` ist gefüllt** → Dateisystem-Modus. Du musst zusätzlich
  `upload_area/` kopieren (Schritt 2 unten) — ohne das funktionieren nach der Migration alle
  Anhang-Downloads nicht, obwohl die Datenbank-Migration selbst fehlerfrei durchlief.
- **`content_bytes` hat echte Werte > 0** → Datenbank-Modus. `pgloader` migriert das automatisch mit,
  weil es Teil der Tabelle ist — hier ist nichts zusätzlich zu tun.

## Schritt 1: Den echten Produktivdump statt Testdaten holen

Auf dem **Produktivserver** (nicht der Demo-VM):

```bash
mysqldump \
  --single-transaction \
  --routines --triggers \
  --hex-blob \
  --default-character-set=utf8mb4 \
  -u root -p testlink > testlink_prod_$(date +%Y-%m-%d).sql
```

Jede Option hat einen konkreten Grund:

- `--single-transaction` — der Dump läuft in einer einzigen Transaktion, dadurch bekommst du einen
  **konsistenten Schnappschuss**, ohne die Datenbank für die Dauer des Dumps zu sperren (wichtig, falls
  während des Dumps noch jemand mit TestLink arbeitet).
- `--routines --triggers` — falls die Datenbank gespeicherte Prozeduren/Trigger enthält, werden die
  sonst standardmäßig **nicht** mitgesichert.
- `--hex-blob` — Binärdaten (die `content`-Spalte aus den Anhängen, falls DB-Modus) werden als
  Hex-Werte statt als Rohbytes geschrieben — verhindert Beschädigung beim Übertragen/Öffnen des Dumps
  als Textdatei.
- `--default-character-set=utf8mb4` — erzwingt eine explizite, bekannte Zeichenkodierung beim Export.
  **Prüfe vorher**, welchen Zeichensatz die Produktivdatenbank tatsächlich nutzt (ältere TestLink-Schemas
  wie unser 1.9.16-Ausgangspunkt verwenden teils noch das alte, 3-Byte-`utf8` statt `utf8mb4` — siehe
  `SHOW CREATE TABLE attachments;` auf dem Produktivserver). Falscher Zeichensatz beim Dump ist die
  häufigste Ursache für kaputte Umlaute nach einer Migration.

!!! danger "Sicherheitshinweis"
    Ein Produktivdump enthält echte Nutzerdaten und Passwort-Hashes. Kläre mit deinem Kollegen/Vorgesetzten,
    ob und wie du ihn für Testzwecke verwenden darfst. Übertrage ihn nur verschlüsselt (z. B. `scp` über
    SSH, niemals unverschlüsseltes FTP/E-Mail), lösche ihn von der Demo-VM wieder, sobald der Test
    abgeschlossen ist, und behandle ihn wie das Produktivsystem selbst (Zugriffsrechte `600`).

Übertrage die Datei sicher auf die Demo-VM:

```bash
scp testlink_prod_2026-08-31.sql <benutzer>@<demo-vm-ip>:/tmp/
```

Auf der Demo-VM einspielen — genau wie in [Kapitel 11](11-migration-schritt1-app-upgrade.md), nur mit
dem echten Dump statt `testlink_create_default_data.sql`:

```bash
mysql -u tl_login -p testlink < /tmp/testlink_prod_2026-08-31.sql
```

## Schritt 2: `upload_area/` mitnehmen (nur bei Dateisystem-Modus)

Falls Schritt „Kritischer Punkt" oben ergeben hat, dass Anhänge im Dateisystem liegen, kopierst du das
Verzeichnis zusätzlich zur Datenbank:

```bash
rsync -avz --progress <benutzer>@<prod-server-ip>:/var/testlink/upload_area/ /var/www/testlink/upload_area/
```

- `-a` (archive) — erhält Zeitstempel, Rechte und Verzeichnisstruktur exakt.
- `-v` (verbose) — zeigt, was kopiert wird.
- `-z` (compress) — komprimiert während der Übertragung, schneller bei vielen/großen Dateien über das
  Netzwerk.
- `--progress` — Fortschrittsanzeige, praktisch bei größeren Anhang-Verzeichnissen.

`rsync` statt `cp`/`scp -r`, weil es bei einer unterbrochenen Übertragung **fortsetzen** kann, statt von
vorne zu beginnen — bei größeren Verzeichnissen ein echter Unterschied.

## Schritt 3: Eigene Konfiguration sichten

Kopiere `custom_config.inc.php` **nicht blind** vom alten Server — sie enthält oft serverspezifische
Pfade, alte DB-Einstellungen oder E-Mail-Server-Zugangsdaten. Sieh sie dir an und übernimm gezielt, was
für die neue Umgebung noch gilt (z. B. eigene Custom-Field-Definitionen, Branding, SMTP-Einstellungen) —
in die **neue** `custom_config.inc.php` auf Basis der Vorlage aus dem TestLink-Paket, nicht als 1:1-Kopie.

## Schritt 4: Vollständigkeits-Verifikation — ALLE Tabellen, nicht nur zwei

Kapitel 12 hat exemplarisch zwei Tabellen verglichen. Für eine echte Migration reicht das nicht — die
Produktivdatenbank hat rund 58 Tabellen, und jede könnte theoretisch von der Migration betroffen sein.
Dafür gibt es in diesem Repo ein Skript, das **automatisch alle Tabellen** ermittelt und vergleicht:

```bash
export MYSQL_PWD='DeinMysqlPasswort'
export PGPASSWORD='DeinPostgresPasswort'

./scripts/compare-migration-rowcounts.sh
```

Es fragt `information_schema.tables` nach allen Tabellennamen der MySQL-Quelle ab, zählt dann pro
Tabelle die Zeilen auf beiden Seiten und markiert jede Abweichung. Am Ende siehst du entweder
„Alle Tabellen stimmen überein" oder eine Liste konkreter Tabellen zum Nachprüfen — reproduzierbar bei
jedem Testlauf und beim echten Migrationstermin identisch ausführbar.

## Schritt 5: Stichproben-Tiefenprüfung

Zeilenzahlen sagen nichts über **inhaltliche** Korrektheit aus. Ergänzend, manuell im Browser:

1. Einen Testfall mit Anhang öffnen und den Anhang **herunterladen** — prüft je nach Modus entweder die
   `content`-Spalte oder den Dateisystem-Pfad tatsächlich end-to-end.
2. Einen Testfall mit **mehreren Versionen** (Historie) öffnen — prüft, dass Versionierung korrekt
   mitgewandert ist.
3. Mit einem **nicht-administrativen** Benutzerkonto einloggen — prüft, dass Rechte/Rollen korrekt
   migriert wurden, nicht nur der Admin-Zugang.
4. Einen Testfall-Titel mit **Umlauten/Sonderzeichen** ansehen — die häufigste sichtbare Folge eines
   Zeichensatz-Fehlers aus Schritt 1.

## Checkliste für den echten Migrationstermin

- [ ] Mit Kollegen geklärt: Speichert Prod Anhänge in DB oder Dateisystem? (`$g_repositoryType`)
- [ ] Zeichensatz der Produktivdatenbank geprüft (`SHOW CREATE TABLE ...`)
- [ ] Wartungsfenster/Downtime abgestimmt
- [ ] Frischer `mysqldump` unmittelbar vor der Migration (Rollback-Basis)
- [ ] Dump sicher übertragen, nach Testende wieder gelöscht
- [ ] `upload_area/` kopiert, falls Dateisystem-Modus
- [ ] `pgloader`-Lauf durchgeführt (Kapitel 12)
- [ ] `./scripts/compare-migration-rowcounts.sh` — alle Tabellen stimmen überein
- [ ] Stichproben (Anhang, Historie, Nicht-Admin-Login, Sonderzeichen) manuell geprüft
- [ ] `custom_config.inc.php` gezielt übertragen, nicht blind kopiert

## Was du gelernt hast

- "Die Daten" einer Anwendung sind oft mehr als nur ihre Datenbank — bei TestLink potenziell auch ein
  komplettes Dateisystem-Verzeichnis.
- Ein Datenbankschema kann mehr Spalten enthalten, als eine bestimmte Konfiguration tatsächlich nutzt
  (`content` vs. `file_path`) — der Blick in den Quellcode/die Konfiguration ist zuverlässiger als eine
  Annahme.
- `mysqldump`-Flags sind keine Standardfloskel, sondern lösen jeweils ein konkretes Problem
  (Konsistenz, Zeichensatz, Binärdaten).
- Ein Skript, das **alle** Tabellen statt einer Stichprobe vergleicht, ist bei ~58 Tabellen kein Luxus,
  sondern der einzige Weg, wirklich sicher zu sein.

## Verständnis-Check

1. Warum kann eine Migration mit `pgloader` fehlerfrei durchlaufen, aber trotzdem alle Anhänge in
   TestLink danach kaputt sein?
2. Wie findest du für eure konkrete Produktivinstanz heraus, ob Anhänge in der DB oder im Dateisystem
   liegen, ohne den Quellcode selbst zu lesen?
3. Warum ist `--single-transaction` bei `mysqldump` wichtig, wenn während des Dumps noch jemand mit
   TestLink arbeiten könnte?
4. Warum reicht ein Vergleich von zwei Tabellen (wie in Kapitel 12 zur Veranschaulichung) für eine echte
   Migration nicht aus?

Zurück zur Übersicht: [Lernpfad-Startseite](README.md).
