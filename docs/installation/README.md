# Installation: Von der Proxmox-VM bis zur laufenden Anwendung

Diese Kapitel sind für dich, wenn du **jeden Schritt selbst tippen, verstehen und später auswendig
erklären können willst** — nicht nur ein Skript laufen lassen. Du baust hier exakt denselben Stack wie
in `scripts/`, aber **von Hand**, mit Erklärung *warum* jeder Befehl nötig ist. Am Ende hast du die
**Zielumgebung** (aktuelle TestLink-Version + PostgreSQL) fertig aufgesetzt und verstanden.

## Für wen ist das?

Für dich als Azubi: Du willst am Ende erklären können, was `a2enmod`, `pg_hba.conf`, `chown www-data`
oder ein VirtualHost eigentlich *tun* — nicht nur, dass ein Skript sie ausführt. Die `scripts/*.sh`-Dateien
im Hauptverzeichnis sind später dein Spickzettel für Prod, wenn du das schon verstanden hast.

## Wie du das benutzt

1. Lies jedes Kapitel **komplett**, bevor du tippst — die Erklärungen stehen bewusst *vor* den Befehlen.
2. Tippe die Befehle **selbst ab** (nicht copy-paste), das prägt sich mehr ein.
3. Jedes Kapitel endet mit:
   - **„Was du gelernt hast"** — Zusammenfassung der Konzepte
   - **„Verständnis-Check"** — Fragen, die du dir selbst beantworten solltest, bevor du weitermachst
4. Wenn ein Verständnis-Check dich stoppt: das ist gut so. Lies den Abschnitt nochmal oder frag nach.

## Kapitelübersicht

Spalte „Erst lesen" verweist auf die passende Seite in [`docs/grundlagen/`](../grundlagen/README.md) —
was das jeweilige Werkzeug ist, woher es kommt, wofür es da ist. Lies sie **vor** dem Kapitel, dann
verstehst du die Befehle darin, statt sie nur nachzutippen.

| # | Kapitel | Worum es geht | Erst lesen |
|---|---|---|---|
| 0 | [Proxmox VE: Debian-VM erstellen](00-proxmox-vm.md) | ISO holen, VM anlegen, Debian installieren, per SSH verbinden | [Debian/Linux](../grundlagen/debian-linux.md) |
| 1 | [Linux-Grundlagen für dieses Projekt](01-linux-basics.md) | sudo, apt, systemctl, Dateirechte — das Handwerkszeug für alles Folgende | [Debian/Linux](../grundlagen/debian-linux.md) |
| 2 | [Apache von Hand installieren](02-apache.md) | Webserver-Grundlagen, Pakete, MPM, erster Test | [Apache](../grundlagen/apache.md) |
| 3 | [PHP von Hand installieren](03-php.md) | Wie PHP mit Apache zusammenarbeitet, Erweiterungen, warum welche | [PHP](../grundlagen/php.md) |
| 4 | [PostgreSQL von Hand einrichten](04-postgresql.md) | Rollen, Authentifizierung, `pg_hba.conf` Zeile für Zeile | [PostgreSQL](../grundlagen/postgresql.md) |
| 5 | [TestLink-Quellcode holen](05-testlink-source.md) | Tags/Releases verstehen, Download, Entpacken, Rechte | [TestLink](../grundlagen/testlink.md) |
| 6 | [Apache-VirtualHost von Hand schreiben](06-virtualhost.md) | Was ein VirtualHost ist, jede Zeile erklärt | [Apache](../grundlagen/apache.md) |
| 7 | [Web-Installer durchklicken](07-web-installer.md) | Der PHP-Installations-Assistent, was im Hintergrund passiert | [TestLink](../grundlagen/testlink.md) |
| 8 | [Verifikation & Debugging-Handwerkszeug](08-verification-debugging.md) | Logs lesen, Fehler eingrenzen, konkrete Fehlerbilder mit Lösung | — |
| 9 | [Absichern & Brücke zu Prod](09-hardening-and-prod.md) | Was du für Prod änderst, was gleich bleibt | — |

## Und danach?

Sobald die Installation steht, geht es mit der eigentlichen Aufgabe weiter:
**[Migration: TestLink 1.9.16/MySQL → PostgreSQL](../migration/README.md)** — die Demo-VM aus diesen
Kapiteln wird dort um MySQL/MariaDB ergänzt, um den echten Produktiv-Migrationsweg nachzubilden und zu
testen.

## Verhältnis zu den anderen Ordnern in diesem Repo

- [`docs/grundlagen/`](../grundlagen/README.md): **was** die einzelnen Werkzeuge (PHP, Apache,
  PostgreSQL, MySQL/MariaDB, pgloader, Debian, TestLink) überhaupt sind, woher sie kommen, wofür sie
  gedacht sind — unabhängig von den konkreten Befehlen.
- [`docs/migration/`](../migration/README.md): die eigentliche Migration, baut auf den hier
  aufgesetzten Kapiteln 0–9 auf.
- `scripts/*.sh`: automatisierte Variante der Installations-Schritte 0–9 — nützlich, wenn du (oder ein
  Kollege) das Ganze *schnell* reproduzieren will, ohne alles nochmal zu tippen (z. B. für einen zweiten
  Prod-Server).

Empfehlung: **Grundlagen-Seite → Installations-Kapitel → (später) Skripte lesen** — dann verstehst du
auch jede Zeile darin.
