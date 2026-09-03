# Betrieb: TestLink im Alltag verantworten

Die anderen Ordner bringen dich zu einer laufenden, migrierten TestLink-Instanz —
[`installation/`](../installation/README.md) baut die Zielumgebung, [`migration/`](../migration/README.md)
zieht die Produktivdaten um. Dieser Ordner ist der Teil danach: **was ein Verantwortlicher im
Tagesgeschäft tatsächlich können muss**, nicht nur einmalig beim Aufsetzen.

## Kapitel

| # | Kapitel | Worum es geht |
|---|---|---|
| 0 | [Checkliste: Produktivumzug](00-checkliste-produktivumzug.md) | Alles aus `installation/` + `migration/` als eine abhakbare Liste für den echten Termin |
| 1 | [Benutzerverwaltung in TestLink](01-user-management.md) | Rollen/Rechte-Modell, Benutzer/Projekte anlegen, wer darf was |
| 2 | [Backup & Restore im laufenden Betrieb](02-backup-restore.md) | Regelmäßige Sicherung (nicht nur die einmalige Migrations-Sicherheit), Restore-Test |
| 3 | [Performance & Monitoring](03-performance-monitoring.md) | Worauf du im laufenden Betrieb achten musst, bevor es zum Problem wird |
| 4 | [Upgrade-Strategie](04-upgrade-strategy.md) | TestLink künftig aktualisieren, ohne dass es eine „Migration" ist |
| 5 | [Häufige Alltagsprobleme](05-common-issues.md) | Was im laufenden Betrieb typischerweise schiefgeht — abseits der Installations-Fehler aus `installation/08` |

## Warum ein eigener Ordner dafür

Eine Installation und ein laufender Betrieb sind zwei unterschiedliche Kompetenzen. Nach der Migration
bist du (voraussichtlich) die Person, die gefragt wird, wenn ein Kollege einen neuen Benutzer braucht,
ein Backup fehlschlägt oder TestLink langsam wird — nicht mehr, wie man es installiert. Dieser Ordner
bereitet gezielt darauf vor.

## Bezug zu den anderen Ordnern

- [`docs/grundlagen/`](../grundlagen/README.md) — Hintergrundwissen zu den beteiligten Werkzeugen
- [`docs/installation/`](../installation/README.md) — wie die Umgebung entstanden ist
- [`docs/migration/`](../migration/README.md) — wie die Produktivdaten dorthin gekommen sind
