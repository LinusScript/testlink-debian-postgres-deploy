# 1 – Benutzerverwaltung in TestLink

## Ziel dieses Kapitels

Verstehen, wie TestLinks Rechte-System **wirklich** aufgebaut ist (nicht nur "Admin kann alles, Rest
nicht") — damit du Kollegen korrekt anlegen und einordnen kannst, ohne bei jedem Fall nachschlagen zu
müssen.

## Konzept: Zwei Ebenen von Rechten

TestLink kennt Rechte auf **zwei unabhängigen Ebenen**, die man nicht verwechseln darf:

1. **System-Ebene**: Ist ein Benutzer überhaupt System-Administrator? Das ist ein einzelnes Flag pro
   Benutzerkonto, unabhängig von einzelnen Projekten.
2. **Projekt-Ebene**: Innerhalb eines konkreten **Test-Projekts** bekommt jeder Benutzer eine **Rolle**
   zugewiesen — und diese Rolle kann von Projekt zu Projekt unterschiedlich sein. Derselbe Mensch kann
   in Projekt A "Leader" und in Projekt B nur "Guest" sein.

Das ist ein bewusstes Design: Ein System-Administrator muss nicht automatisch in jedem einzelnen
Test-Projekt inhaltlich mitreden dürfen, und ein Team-Leiter braucht keine System-Admin-Rechte, um sein
eigenes Projekt zu führen.

## Die Standard-Rollen (aus dem TestLink-Quellcode)

Ich habe die Standard-Rollen direkt aus den Installationsdaten geprüft
(`install/sql/mysql/testlink_create_default_data.sql`) — das sind exakt die sechs, die nach einer
frischen Installation zur Auswahl stehen:

| Rolle | Typische Verwendung |
|---|---|
| **admin** | Volle Kontrolle über das Projekt (Struktur, Rechte, alles) |
| **leader** | Projektleitung — Planung, Testpläne anlegen, Ergebnisse auswerten, aber nicht zwingend System-Admin |
| **senior tester** | Erfahrene Tester mit erweiterten Rechten (z. B. Testfälle anlegen/ändern) |
| **tester** | Führt zugewiesene Testfälle aus, trägt Ergebnisse ein — die häufigste Rolle im Alltag |
| **test designer** | Darf Testfälle anlegen/bearbeiten, aber keine Testläufe durchführen |
| **guest** | Nur lesender Zugriff — praktisch für Stakeholder, die den Fortschritt verfolgen wollen, ohne etwas zu verändern |

Dahinter steckt technisch ein **granulares Rechtesystem**: Jede Rolle ist eine Sammlung einzelner
**Rechte** (z. B. `testplan_execute`, `mgt_modify_tc` = Testfälle bearbeiten, `mgt_users` =
Benutzerverwaltung) — die Rollen sind also nur sinnvoll vorbelegte Bündel, keine hart einprogrammierten
Sonderfälle. Für den Alltag reicht es, die sechs Standard-Rollen zu kennen; dass sie aus einzelnen
Rechten zusammengesetzt sind, erklärt, warum in der Oberfläche gelegentlich von "Rechten" statt
"Rollen" die Rede ist.

## Praktisch: Neuen Benutzer anlegen

1. Als System-Administrator einloggen.
2. **Startseite → Benutzerverwaltung** (System-Ebene) → **Neuer Benutzer**.
3. Benutzername, Name, E-Mail, initiales Passwort vergeben. Hier legst du **nicht** die Projektrolle
   fest — nur, dass der Account existiert.
4. Anschließend in das jeweilige **Test-Projekt** wechseln → **Benutzer-Rollen-Zuordnung** (manchmal
   auch beim Anlegen/Bearbeiten eines Projekts erreichbar) → den neuen Benutzer auswählen und eine der
   sechs Rollen zuweisen.

**Häufiger Fehler:** Ein Benutzer wurde angelegt, kann sich einloggen, sieht aber kein Projekt oder kann
nichts tun. Grund fast immer: Schritt 4 wurde vergessen — der Account existiert, hat aber in keinem
Projekt eine Rolle.

## Praktisch: Rolle ändern oder entziehen

Gleicher Weg wie beim Zuweisen — Benutzer-Rollen-Zuordnung im jeweiligen Projekt öffnen, Rolle ändern
oder auf "keine Rolle"/entfernen setzen. Wichtig: Das **löscht den Benutzer nicht**, es entzieht ihm nur
den Zugriff auf dieses eine Projekt — in anderen Projekten behält er seine dortige Rolle.

## Was Rollenverwaltung NICHT ist

Das ist reine TestLink-Anwendungslogik, gespeichert in der Datenbank (Tabellen `users`, `roles`,
`rights`, `role_rights`, projektspezifische Zuordnungstabellen) — **nichts davon hat mit den Linux-
oder PostgreSQL-Benutzern zu tun**, die du in [`installation/`](../installation/README.md) und
[`migration/`](../migration/README.md) angelegt hast (`tl_login`, `postgres`, dein SSH-Benutzer). Das
sind zwei komplett getrennte Systeme auf unterschiedlichen Ebenen — Verwechslung ist ein häufiger
Anfängerfehler.

## Was du gelernt hast

- TestLink-Rechte existieren auf zwei Ebenen: System (Admin ja/nein) und Projekt (eine von sechs
  Rollen, pro Projekt einzeln).
- Rollen sind Bündel einzelner, granularer Rechte — keine Sonderfälle im Code.
- Ein neu angelegter Benutzer braucht **zwingend** eine explizite Projekt-Rollenzuweisung, sonst sieht
  er nichts.
- TestLink-Benutzer und System-/Datenbank-Benutzer (Linux, PostgreSQL) sind vollständig getrennte Konzepte.

## Verständnis-Check

1. Ein Kollege ist System-Administrator. Darf er automatisch in jedem Test-Projekt Testfälle bearbeiten?
2. Was ist der Unterschied zwischen den Rollen "tester" und "test designer"?
3. Ein neuer Mitarbeiter kann sich einloggen, sieht aber "Keine Projekte verfügbar". Was hast du
   wahrscheinlich vergessen?

Weiter mit [Kapitel 2: Backup & Restore im laufenden Betrieb](02-backup-restore.md).
