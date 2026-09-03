# Grundlagen: Die Werkzeuge hinter unserem TestLink-Stack verstehen

## Warum dieser Ordner existiert

In `docs/tutorial/` lernst du, **wie** man diesen Stack Schritt für Schritt aufbaut. Dieser Ordner
beantwortet eine andere, mindestens genauso wichtige Frage: **Was ist eigentlich jedes einzelne
Werkzeug, das wir da benutzen — und warum genau dieses und kein anderes?**

Der Unterschied ist nicht akademisch. Wer nur eine Installationsanleitung abtippt, kann sie wiederholen,
solange nichts Unerwartetes passiert. Wer versteht, *was* Apache, PHP, PostgreSQL und TestLink jeweils
sind, *wofür* sie entwickelt wurden und *wie* sie zusammenspielen, kann auch dann noch handeln, wenn
etwas vom Skript abweicht — und genau das brauchst du, wenn du perspektivisch die Verantwortung für die
TestLink-Anwendung übernimmst.

## Die Werkzeuge in unserem Stack

| Werkzeug | Rolle in unserem Stack | Seite |
|---|---|---|
| **TestLink** | Die Anwendung selbst — worum es eigentlich geht | [testlink.md](testlink.md) |
| **PHP** | Führt den TestLink-Code aus | [php.md](php.md) |
| **Apache** | Nimmt Web-Anfragen entgegen, reicht sie an PHP weiter | [apache.md](apache.md) |
| **PostgreSQL** | Unsere Ziel-Datenbank | [postgresql.md](postgresql.md) |
| **MySQL/MariaDB** | Die Datenbank der (noch) produktiven Ausgangslage | [mariadb-mysql.md](mariadb-mysql.md) |
| **pgloader** | Migrationswerkzeug zwischen den beiden Datenbanken | [pgloader.md](pgloader.md) |
| **Debian/Linux** | Das Betriebssystem, auf dem alles läuft | [debian-linux.md](debian-linux.md) |

## Wie jede Seite aufgebaut ist

Jede Seite beantwortet dieselben Fragen, in derselben Reihenfolge — damit du dir eine Routine
angewöhnst, mit der du auch **jedes zukünftige, hier nicht behandelte Werkzeug** selbst einordnen kannst:

1. **Kurzfassung** — eine Zeile, die reicht, um es einem Kollegen zu erklären, der es nicht kennt.
2. **Geschichte** — wo kommt es her, welches Problem sollte es ursprünglich lösen? (Das erklärt oft,
   *warum* ein Werkzeug so funktioniert, wie es funktioniert — Design-Entscheidungen sind selten
   willkürlich.)
3. **Kernkonzept** — was macht es *grundsätzlich*, unabhängig von unserem konkreten Projekt?
4. **Wofür wird es verwendet** — allgemein in der Praxis, und konkret in unserem TestLink-Stack.
5. **Wichtige Begriffe** — Vokabular, das du kennen musst, um Dokumentation/Fehlermeldungen zu verstehen.
6. **Die wichtigsten Befehle** — nicht auswendig lernen, sondern verstehen, was jeder Befehl *bewirkt*.
7. **Bezug zu unserem Projekt** — Verweis auf die konkreten Tutorial-Kapitel, in denen du es einsetzt.

## Verhältnis zu `docs/tutorial/`

- `docs/tutorial/` = **wie** du etwas aufbaust (Schritt für Schritt, mit Befehlen zum Mittippen).
- `docs/grundlagen/` (hier) = **was** die einzelnen Werkzeuge sind und **warum** sie existieren.

Empfehlung: Lies die passende Grundlagen-Seite, **bevor** du das zugehörige Tutorial-Kapitel bearbeitest
— dann verstehst du die Befehle dort nicht nur, sondern kannst einordnen, warum sie so und nicht anders
lauten.
