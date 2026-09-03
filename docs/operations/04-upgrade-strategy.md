# 4 – Upgrade-Strategie

## Ziel dieses Kapitels

Verstehen, wie du TestLink **künftig**, Jahre nach der Migration, auf eine neuere Version bringst — als
normale Wartungsaufgabe, nicht als Großprojekt wie die einmalige Migration von 1.9.16.

## Die gute Nachricht: Du kennst den Mechanismus schon

Ein normales Versions-Upgrade ist **exakt derselbe Mechanismus**, den du in
[Migrations-Kapitel 2](../migration/02-schritt1-app-upgrade.md) bereits durchgeführt hast — nur ohne die
zusätzliche Komplikation eines Datenbank-Engine-Wechsels. Kurz zusammengefasst (Details siehe dort):

1. Neue TestLink-Codebasis herunterladen (wie in
   [`installation/05`](../installation/05-testlink-source.md)).
2. Die zwischen deiner aktuellen und der neuen Version liegenden SQL-Dateien aus
   `install/sql/alter_tables/<version>/postgres/` **in der richtigen Reihenfolge** einspielen (bei uns:
   PostgreSQL-Variante statt der MySQL-Variante aus der Migration).
3. Über die `db_version`-Tabelle verifizieren, dass der Schema-Stand jetzt der neuen Version entspricht
   (Prinzip aus [Migrations-Kapitel 1](../migration/01-konzept.md)).
4. Neue Codebasis ausrollen (alte Dateien ersetzen, `config_db.inc.php` und `custom_config.inc.php`
   **behalten** — die gehören nicht zum Code-Release).

## Der einzige Unterschied zur Migration

Bei der Migration musstest du zusätzlich die Datenbank-**Engine** wechseln (MySQL → PostgreSQL) — dafür
gab es Migrations-Kapitel 3 mit `pgloader`. Ein normales Versions-Upgrade bleibt auf **derselben** Engine
(PostgreSQL bleibt PostgreSQL) — du brauchst also nur den Teil aus Migrations-Kapitel 2, **kein**
`pgloader`.

## Checkliste für ein normales Versions-Upgrade

- [ ] Release-Notes/Changelog der Ziel-Version lesen — gibt es bekannte Breaking Changes?
- [ ] Frisches Backup ziehen (siehe [Kapitel 2](02-backup-restore.md)) — dein Rollback-Plan, falls etwas
      schiefgeht.
- [ ] Wartungsfenster ankündigen (auch bei kleinen Updates — die DB-Migration braucht kurz exklusiven
      Zugriff).
- [ ] Auf einer **Test-Instanz** (nicht direkt produktiv!) den kompletten Ablauf einmal durchspielen —
      genau wie du die echte Migration zuerst auf der Demo-VM getestet hast, bevor du sie produktiv
      gemacht hast. Dasselbe Prinzip gilt für jedes künftige Update.
- [ ] `install/sql/alter_tables/<version>/postgres/...` Schritt für Schritt einspielen.
- [ ] `db_version` prüfen.
- [ ] Neue Codebasis ausrollen, `config_db.inc.php`/`custom_config.inc.php` erhalten.
- [ ] Stichproben im Browser (Login, ein Testfall, ein Report) — analog zu den Prüfungen aus
      [Migrations-Kapitel 3](../migration/03-schritt2-db-wechsel.md).

## Warum "auf einer Test-Instanz zuerst" auch hier gilt

Das ist keine einmalige Vorsichtsmaßnahme nur für die große Migration gewesen — es ist ein
**wiederverwendbares Prinzip**: Jede Änderung an einer produktiven Datenbank sollte zuerst gegen eine
Kopie/Testinstanz laufen. Der einfachste Weg, das für ein künftiges Update zu tun: dieselbe Demo-VM aus
[`installation/`](../installation/README.md) wiederverwenden, mit einem aktuellen Backup der Produktion
befüllen (siehe [Kapitel 2](02-backup-restore.md)), und dort zuerst upgraden.

## Was du gelernt hast

- Ein normales TestLink-Versions-Upgrade ist derselbe SQL-Migrationsmechanismus wie beim großen Umzug,
  nur ohne Engine-Wechsel.
- `config_db.inc.php` und `custom_config.inc.php` sind Konfiguration, kein Code — sie überleben jedes
  Update unverändert.
- "Erst auf einer Testinstanz, dann produktiv" ist kein Einmal-Vorgehen für die Migration, sondern eine
  Faustregel für jede künftige Änderung an der Produktivdatenbank.

## Verständnis-Check

1. Was entfällt bei einem normalen Versions-Upgrade im Vergleich zur ursprünglichen Migration?
2. Warum darfst du `config_db.inc.php` beim Ausrollen einer neuen Version nicht überschreiben?
3. Woher bekommst du eine realistische Testumgebung für ein künftiges Upgrade, ohne die Produktion zu
   riskieren?

Weiter mit [Kapitel 5: Häufige Alltagsprobleme](05-common-issues.md).
