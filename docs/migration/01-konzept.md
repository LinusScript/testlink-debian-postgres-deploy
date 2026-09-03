# 1 – Migrationskonzept: Warum „einfach umziehen" nicht geht

## Ausgangslage

Das ist kein rein hypothetisches Übungsszenario mehr, sondern bildet eine echte Migration nach:

| | Ist-Zustand (Produktion) | Soll-Zustand |
|---|---|---|
| **TestLink-Version** | 1.9.16 | 1.9.20-20251208 (der Tag, den wir seit Kapitel 5 nutzen) |
| **Datenbank** | MySQL / MariaDB | PostgreSQL |

Bevor du irgendetwas an der echten Produktivinstanz änderst, bauen wir **beide** Schritte hier auf der
Demo-VM nach und testen sie — genau der Sinn dieses ganzen Repos.

## Ziel dieses Kapitels

Verstehen, warum diese Migration **zwei unabhängige Probleme** sind, die man **nicht gleichzeitig**
lösen sollte — und warum, belegt direkt im TestLink-Quellcode, nicht nur behauptet.

## Konzept 1: Code-Version und Datenbank-Version sind zwei getrennte Dinge

Wenn du TestLink aktualisierst, passiert eigentlich Zweierlei:

1. **Der PHP-Code** wird ausgetauscht (neue Dateien statt alte — reines Kopieren, wie in Kapitel 5).
2. **Die Datenbank-Struktur** (Tabellen, Spalten, Views) muss an den neuen Code angepasst werden —
   und zwar **ohne** die vorhandenen Daten zu verlieren. Das geht nicht durch Kopieren, sondern nur
   durch gezielte `ALTER TABLE`/`CREATE VIEW`-Befehle, die den bestehenden Datenbestand umbauen.

TestLink verfolgt den Stand der Datenbank in einer eigenen Tabelle: **`db_version`**. Jede
Versions-Migration fügt dort am Ende eine Zeile ein — das habe ich im Quellcode nachgesehen
(`install/sql/alter_tables/1.9.17/mysql/DB.1.9.17/stepZ/z_final_step.sql`):

```sql
INSERT INTO /*prefix*/db_version (version,notes,upgrade_ts)
VALUES('DB 1.9.17', 'TestLink 1.9.17 Alan Turing', CURRENT_TIMESTAMP());
```

Das bedeutet: **Die Datenbank "weiß" selbst, auf welchem Versionsstand sie ist** — unabhängig davon,
welche Code-Version gerade läuft. Genau das nutzen wir gleich zur Verifikation.

## Konzept 2: Warum unterscheidet TestLink zwischen MySQL und PostgreSQL überhaupt?

SQL ist **nicht vollständig portabel** zwischen Datenbanksystemen. Ein paar konkrete Unterschiede, die
TestLinks Code direkt betreffen:

| | MySQL/MariaDB | PostgreSQL |
|---|---|---|
| Auto-increment-Spalten | `AUTO_INCREMENT` | `SERIAL` / Sequenzen |
| Bezeichner in Anführungszeichen | `` `backtick` `` | `"doppelte Anführungszeichen"` |
| Wahrheitswerte | oft `TINYINT(1)` | echter `BOOLEAN`-Typ |
| Engine-Angaben | `ENGINE=InnoDB` | kennt PostgreSQL nicht |

Deshalb pflegt TestLink **komplett getrennte SQL-Skript-Sätze** pro Datenbank — das haben wir schon in
[Kapitel 4](../installation/04-postgresql.md) gesehen (`install/sql/postgres/`) und bei den Versions-Upgrades ist es
genauso: `install/sql/alter_tables/<version>/mysql/`, `.../postgres/`, `.../mssql/` — je eigene Dateien,
weil die Befehle nicht 1:1 übertragbar sind. Es gibt **keine** Funktion in TestLink, die eine
MySQL-Datenbank automatisch in eine PostgreSQL-Datenbank umwandelt.

## Konzept 3: Was der TestLink-Installer bei einem Versions-Update wirklich tut (und was nicht)

Ich habe im Quellcode nachgesehen, was passiert, wenn man die installierte TestLink-Version aktualisiert.
Die Installer-Startseite (`install/index.php`) sagt es sogar ausdrücklich:

> „Migration to latest version ( ... ) requires Database changes that has to be done **MANUALLY**."

Es gibt in der aktuellen Oberfläche **keinen** funktionierenden Web-Assistenten für ein automatisches
Datenbank-Update mehr (nur einen Link „New installation" — eine Update-Funktion existiert zwar noch als
Code-Reste, ist aber nicht mehr über die Oberfläche erreichbar). Ein Versions-Update bedeutet also: **du
führst die passenden SQL-Dateien selbst aus**, in der richtigen Reihenfolge. Genau das machen wir in
[Migrations-Kapitel 2](02-schritt1-app-upgrade.md) — nachvollziehbar, Schritt für Schritt.

## Die Zwei-Schritte-Strategie

Daraus folgt eine bewusste Reihenfolge, die **nicht willkürlich** ist:

```
Schritt 1 (Migrations-Kapitel 2)    Schritt 2 (Migrations-Kapitel 3)
TestLink 1.9.16   →   1.9.20        TestLink 1.9.20   →   1.9.20
MySQL             →   MySQL         MySQL             →   PostgreSQL
       (nur App-Version ändert sich)      (nur DB-Engine ändert sich)
```

**Warum nicht beides auf einmal?** Weil dann bei einem Fehler unklar wäre, welche der beiden Änderungen
ihn verursacht hat — genau das Debugging-Prinzip aus [Kapitel 8](../installation/08-verification-debugging.md)
("welche Schicht ist betroffen?"), nur auf Migrationsschritte statt auf Systemschichten angewendet.
Getrennt getestet ist jeder Schritt für sich nachvollziehbar, und wenn etwas schiefgeht, weißt du sofort,
in welchem der beiden Schritte.

**Schritt 1** hält die Datenbank-Engine (MySQL) konstant und ändert nur die App-Version — dadurch lässt
sich der Schritt 1:1 mit den offiziellen, versionierten SQL-Dateien von TestLink nachvollziehen.

**Schritt 2** hält die App-Version (jetzt bereits 1.9.20) konstant und ändert nur die Engine — dadurch
migrierst du in ein Ziel-Schema, das du schon kennst (dasselbe PostgreSQL-Schema aus den Kapiteln 4–7),
statt gleichzeitig gegen ein bewegliches Ziel zu arbeiten.

## Was du gelernt hast

- Code-Version und Datenbank-Schema-Version sind getrennte Konzepte; TestLink verfolgt Letztere in der
  Tabelle `db_version`.
- SQL ist zwischen Datenbanksystemen nicht portabel — deshalb pflegt TestLink pro Engine eigene
  SQL-Skripte, ohne automatische Konvertierung zwischen ihnen.
- Der TestLink-Web-Installer bietet für Versions-Updates aktuell keinen automatisierten Assistenten mehr
  — das SQL wird manuell ausgeführt.
- Eine riskante Migration in unabhängig testbare Einzelschritte zu zerlegen ist keine Umständlichkeit,
  sondern reduziert die Fehlersuche bei Problemen erheblich.

## Verständnis-Check

1. Warum reicht es nicht, einfach die neuen TestLink-Dateien auf den Server zu kopieren?
2. Woran erkennt man im TestLink-Quellcode, auf welchem Schema-Stand eine Datenbank aktuell ist?
3. Warum migrieren wir nicht direkt von "TestLink 1.9.16 auf MySQL" zu "TestLink 1.9.20 auf PostgreSQL"
   in einem Schritt?

Weiter mit [Migrations-Kapitel 2: Schritt 1 – TestLink 1.9.16 auf MySQL aktualisieren](02-schritt1-app-upgrade.md).
