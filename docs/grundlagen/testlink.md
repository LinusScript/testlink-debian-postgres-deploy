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
automatischen Update-Assistenten mehr gibt (Migrations-Kapitel 1), warum verschiedene Community-Tags existieren
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

### Ein Beispiel, damit es greifbar wird

Angenommen, dein Team testet eine Login-Seite vor einem Release:

1. Jemand legt in TestLink einen **Testfall** an: „Login mit falschem Passwort" — mit klaren
   Schritten ("Benutzername eingeben, falsches Passwort eingeben, auf Login klicken") und einem
   erwarteten Ergebnis ("Fehlermeldung 'Ungültige Zugangsdaten' erscheint").
2. Dieser Testfall landet in einer **Test-Suite** namens „Login & Authentifizierung", zusammen mit
   ähnlichen Testfällen (richtiges Passwort, gesperrter Account, ...).
3. Vor dem Release wird ein **Testplan** „Release 2.4" erstellt, der diese Test-Suite (und andere)
   enthält.
4. Ein Tester arbeitet den Testplan ab, führt jeden Testfall aus und trägt das Ergebnis als
   **Testlauf** ein: bestanden, fehlgeschlagen, oder blockiert (z. B. weil eine Vorbedingung nicht
   erfüllt war).
5. Am Ende zeigt TestLink einen Report: 47 von 50 Testfällen für Release 2.4 bestanden, 3
   fehlgeschlagen — mit direktem Link zu den fehlgeschlagenen Testfällen samt Details.

Ohne ein Werkzeug wie TestLink würde das über Excel-Tabellen oder E-Mails laufen — schnell
unübersichtlich, sobald mehrere Personen gleichzeitig testen oder ein Testfall über mehrere
Release-Zyklen hinweg wiederholt wird.

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
  Migrations-Kapitel 3 als `nodes_hierarchy`/`tcversions` bereits im Datenbankschema gesehen).
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
| `install/sql/<engine>/` | Die Datenbankschema-Definitionen je Datenbanktyp (siehe Migrations-Kapitel 1) |
| `install/sql/alter_tables/<version>/` | Versions-Migrationsskripte (siehe Migrations-Kapitel 2) |
| `upload_area/` | Datei-Anhänge, falls im Dateisystem-Modus (siehe Migrations-Kapitel 4) |

## Bezug zu unserem Projekt

- [Kapitel 5](../installation/05-testlink-source.md) — wie du die TestLink-Codebasis besorgst
- [Kapitel 7](../installation/07-web-installer.md) — was beim Installieren technisch passiert
- [Migrations-Kapitel 1–4](../migration/01-konzept.md) — die eigentliche Versions- und Datenbank-Migration
