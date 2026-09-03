# Was ist TestLink?

## Kurzfassung

TestLink ist eine webbasierte **Testmanagement-Software**: ein Werkzeug, mit dem Teams Testfälle
planen, organisieren, ausführen und deren Ergebnisse nachverfolgen — die Anwendung, um die sich dieses
ganze Repo dreht.

## Geschichte

TestLink wurde von **Chad Rosen** entwickelt, einem Softwareentwickler bei der Firma Good Technology in
den frühen 2000er-Jahren. Der Auslöser war ein ganz praktisches Problem: Sein Entwicklungsteam tat sich
schwer, manuell nachzuverfolgen, welche QA-Testfälle bereits durchgeführt wurden und welche nicht —
klassische Tabellenkalkulationen wurden schnell unübersichtlich. Rosen und sein Manager Mike Belshe
schrieben daraufhin ein eigenes Werkzeug dafür. Good Technology erlaubte, es als Open Source zu
veröffentlichen: Das SourceForge-Projekt startete am 25. September 2003. Version 1.0.4 (Mai 2004) war
die letzte, an der Rosen selbst mitarbeitete — danach übernahm **Francisco Mancardi** die
Projektführung, und eine Community entwickelte TestLink über die Jahre kontinuierlich weiter (der
Versionsstand, den wir in diesem Repo nutzen, `1.9.20`, liegt über 20 Jahre nach dem ursprünglichen
Auslöser-Problem).

**Warum das für dich relevant ist:** TestLink ist kein kommerzielles Produkt eines einzelnen
Unternehmens mit dediziertem Support-Team — es ist ein von Freiwilligen gepflegtes Open-Source-Projekt
(GPL-Lizenz). Das erklärt vieles, was du im Rest dieses Repos gesehen hast: warum es keinen komfortablen
automatischen Update-Assistenten mehr gibt (Kapitel 10), warum verschiedene Community-Tags existieren
(z. B. der PHP-8-kompatible Tag, den wir verwenden), und warum du als zukünftiger Verantwortlicher
selbst tief genug verstehen musst, wie es funktioniert — es gibt keine Support-Hotline, die das für dich
löst.

## Kernkonzept: Was ist "Testmanagement" überhaupt?

Bevor Software ausgeliefert wird, muss geprüft werden, ob sie tut, was sie soll. Bei mehr als ein paar
Testfällen reicht "wir probieren mal ein bisschen rum" nicht mehr — man braucht Struktur:

- **Testfälle** — einzelne, klar definierte Prüfschritte ("Login mit falschem Passwort → Fehlermeldung
  erscheint").
- **Test-Suiten** — Testfälle, thematisch in einer Baumstruktur gruppiert.
- **Testpläne** — eine Auswahl von Testfällen, die für eine bestimmte Version/einen bestimmten
  Meilenstein durchgeführt werden sollen.
- **Testläufe (Executions)** — das dokumentierte Ergebnis: wurde ein Testfall in dieser Version
  ausgeführt, und war das Ergebnis "bestanden", "fehlgeschlagen" oder "blockiert"?
- **Requirements** — fachliche Anforderungen, die man mit Testfällen verknüpfen kann, um nachzuweisen,
  dass jede Anforderung auch tatsächlich getestet wurde.

TestLink bildet genau diese Struktur ab und macht sie für ein ganzes Team gemeinsam nutzbar,
nachvollziehbar und auswertbar (Reports: wie viel Prozent der Testfälle sind für Release X bestanden?).

## Wofür wird es verwendet

Allgemein: überall dort, wo Software-Qualitätssicherung (QA) strukturiert nachvollziehbar sein muss —
oft in Umgebungen mit Nachweispflicht (z. B. regulierte Branchen), aber auch ganz praktisch, um in
größeren Teams den Überblick zu behalten, was schon getestet ist und was nicht.

In unserem Kontext: Die Firma betreibt eine eigene TestLink-Instanz für die interne
Qualitätssicherung — und die soll technisch modernisiert (aktuellere Version) und auf eine andere
Datenbank (PostgreSQL statt MySQL/MariaDB) umgezogen werden. Genau das ist der rote Faden dieses ganzen
Repos.

## Wichtige Begriffe

- **Test-Management-System (TMS)** — Oberbegriff für Software wie TestLink (Alternativen: TestRail,
  Zephyr, qTest).
- **Testfall-Version (`tcversion`)** — TestLink versioniert Testfälle: ändert sich ein Testfall,
  entsteht eine neue Version, alte Versionen bleiben nachvollziehbar erhalten (du hast diese Tabelle in
  Kapitel 12 als `nodes_hierarchy`/`tcversions` bereits im Datenbankschema gesehen).
- **Test-Projekt** — die oberste Organisationseinheit in TestLink, meist ein Produkt oder Team.
- **Requirement-Spec** — eine Sammlung von Anforderungen, die mit Testfällen verknüpft werden können.
- **Custom Fields** — von der eigenen Organisation frei definierbare Zusatzfelder an Testfällen/Projekten
  (z. B. "Priorität nach interner Norm XY").

## Die wichtigsten Befehle/Orte

TestLink selbst ist kein Kommandozeilenwerkzeug — es wird über den Browser bedient. Als zukünftiger
Verantwortlicher sind trotzdem folgende **Orte im Code** wichtiger als einzelne Befehle:

| Ort | Wofür |
|---|---|
| `config.inc.php` | Zentrale Standard-Konfiguration (nicht direkt bearbeiten, siehe unten) |
| `custom_config.inc.php` | **Hier** trägst du eigene Anpassungen ein — überlebt Updates, `config.inc.php` selbst nicht |
| `config_db.inc.php` | Datenbank-Zugangsdaten, vom Installer erzeugt (siehe Kapitel 7) |
| `install/sql/<engine>/` | Die Datenbankschema-Definitionen je Datenbanktyp (siehe Kapitel 10) |
| `install/sql/alter_tables/<version>/` | Versions-Migrationsskripte (siehe Kapitel 11) |
| `upload_area/` | Datei-Anhänge, falls im Dateisystem-Modus (siehe Kapitel 13) |

## Bezug zu unserem Projekt

- [Kapitel 5](../tutorial/05-testlink-source.md) — wie du die TestLink-Codebasis besorgst
- [Kapitel 7](../tutorial/07-web-installer.md) — was beim Installieren technisch passiert
- [Kapitel 10–13](../tutorial/10-migrationskonzept.md) — die eigentliche Versions- und Datenbank-Migration
