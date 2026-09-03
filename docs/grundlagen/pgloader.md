# Was ist pgloader?

## Kurzfassung

`pgloader` ist ein spezialisiertes Werkzeug, um Daten **aus anderen Datenbanksystemen (u. a. MySQL,
SQLite, CSV) nach PostgreSQL zu übertragen** — inklusive automatischer Schema- und Typ-Umwandlung. In
unserem Stack ist es das zentrale Werkzeug für den eigentlichen Datenbank-Wechsel in
[Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md).

## Geschichte

`pgloader` existiert seit 2005 und wurde von **Dimitri Fontaine** entwickelt, einem bekannten Contributor
des PostgreSQL-Projekts. Der Auslöser: Fontaine erlebte in der Praxis wiederholt, wie
Datenbank-Migrationen an PostgreSQLs strikt transaktionalem `COPY`-Befehl scheiterten — ein einziger
fehlerhafter Datensatz konnte den kompletten Import einer riesigen Datei abbrechen lassen. Die erste
Version war in Python geschrieben; weil das für enge Wartungsfenster bei großen Migrationen nicht
schnell genug war, schrieb Fontaine das Werkzeug später komplett in **Common Lisp** neu (die heutige
Version 3.x) — mit deutlich besserer Performance und echter Nebenläufigkeit.

**Warum das für dich relevant ist:** `pgloader` ist bewusst als **Spezialwerkzeug für genau dieses
Problem** entstanden, nicht als Allzweck-Datenbankwerkzeug — deshalb kennt es die typischen Fallstricke
einer MySQL→PostgreSQL-Migration (siehe [Migrations-Kapitel 1](../migration/01-konzept.md)) von Haus aus
und behandelt sie automatisch, statt dass du sie selbst nachbauen müsstest.

## Kernkonzept: Automatisierte Schema- und Datenübertragung

```
MySQL-Quelle              pgloader                    PostgreSQL-Ziel
-----------                --------                    ----------------
Tabellen lesen      →      Typen übersetzen       →    passendes Schema anlegen
Daten lesen          →     Daten kopieren           →   Daten einfügen
AUTO_INCREMENT        →    erkennt Automatik         →  Sequenzen erzeugen + befüllen
```

`pgloader` **liest nur** aus der Quelle — es verändert die MySQL-Datenbank nicht. Das macht wiederholte
Testläufe risikofrei (siehe Migrations-Kapitel 3).

## Wofür wird es verwendet

Allgemein: als Standardwerkzeug für Migrationen von MySQL (und anderen Quellen) nach PostgreSQL — sowohl
für einmalige Migrationsprojekte wie unseres als auch für größere, mehrstufige Datenbank-Umzüge in der
Praxis.

In unserem Kontext: `pgloader` überträgt die (bereits auf die Zielversion aktualisierte) MySQL-Datenbank
aus Migrations-Kapitel 2 vollständig nach PostgreSQL — Schema und Daten in einem Arbeitsschritt.

## Wichtige Begriffe

- **`.load`-Datei** — die Kommandodatei, die `pgloader` steuert (Quelle, Ziel, Optionen).
- **Typ-Cast** — die automatische Übersetzung eines MySQL-Datentyps in den passenden PostgreSQL-Typ
  (z. B. `TINYINT(1)` → `BOOLEAN`).
- **`reset sequences`** — eine `pgloader`-Option, die nach dem Kopieren die PostgreSQL-Sequenzen auf den
  nächsten freien Wert setzt, damit neue Datensätze nicht mit migrierten IDs kollidieren.
- **`include drop`** — eine Option, die vorhandene Tabellen im Ziel vor der Migration verwirft — praktisch
  für wiederholte Testläufe, in Produktion mit Bedacht einzusetzen.

## Die wichtigsten Befehle

```bash
pgloader migrate-testlink.load   # eine Migration anhand einer Kommandodatei ausführen
pgloader --version                 # installierte Version prüfen
```

Der eigentliche "Befehl" bei `pgloader` ist meist nicht die Kommandozeile selbst, sondern der **Inhalt
der `.load`-Datei** — siehe [Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md) für ein
vollständiges, kommentiertes Beispiel.

## Bezug zu unserem Projekt

- [Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md) — vollständiger, erklärter Ablauf
- [Migrations-Kapitel 4](../migration/04-vollstaendigkeit-produktivmigration.md) — warum `pgloader` allein nicht
  reicht (Datei-Anhänge außerhalb der Datenbank)
