# 4 – PostgreSQL von Hand einrichten

## Ziel dieses Kapitels

PostgreSQL läuft, du kannst dich per Passwort über TCP (`127.0.0.1`) verbinden — das ist die Verbindungsart,
die der TestLink-Web-Installer später gleich benutzen wird.

## Was ist PostgreSQL, und was ist eine "Rolle"?

PostgreSQL ist ein relationales Datenbank-Managementsystem (RDBMS): Daten liegen in Tabellen mit fest
definierten Spalten, Beziehungen zwischen Tabellen werden über Fremdschlüssel abgebildet, Abfragen erfolgen
in SQL.

Anders als z. B. MySQL kennt PostgreSQL keine strikte Trennung zwischen "Benutzer" und "Gruppe" — beides
sind **Rollen** (`ROLE`). Eine Rolle kann sich einloggen (dann faktisch ein "Benutzer") und/oder andere
Rollen enthalten (dann faktisch eine "Gruppe"). Bei der Installation legt PostgreSQL automatisch die Rolle
`postgres` an — den **Superuser**, der alles darf (Datenbanken anlegen/löschen, andere Rollen verwalten).

## Wie TestLink seine Datenbank bekommt (wichtig, bevor du weitermachst)

**Wir legen hier keine `testlink`-Datenbank und keinen eigenen DB-User an.** Das erledigt der
TestLink-Web-Installer in Kapitel 7 selbst: Er verbindet sich als `postgres`-Superuser, legt Datenbank +
einen eingeschränkten DB-User (`tl_login`) an, importiert das Schema und speichert die Zugangsdaten. Unsere
Aufgabe hier ist nur, PostgreSQL so vorzubereiten, dass sich der Installer **per Passwort über das Netzwerk**
als `postgres` verbinden kann.

## Schritt 1: PostgreSQL installieren

```bash
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
```

Debian 13 installiert damit **PostgreSQL 17**. Der Dienst startet automatisch:

```bash
sudo systemctl status postgresql
```

## Schritt 2: Wie sich PostgreSQL standardmäßig verhält — und warum das für uns noch nicht reicht

Direkt nach der Installation kannst du dich so verbinden:

```bash
sudo -u postgres psql
```

Das funktioniert ohne Passwort — **warum?** PostgreSQL nutzt für lokale Unix-Socket-Verbindungen
standardmäßig die Methode **`peer`**: Es vertraut dem Linux-Benutzernamen, unter dem der Befehl läuft.
`sudo -u postgres` wechselt den *Linux*-Benutzer zu `postgres`, und weil eine PostgreSQL-Rolle namens
`postgres` existiert, lässt `peer` dich ohne Passwort rein — aber **nur lokal über den Unix-Socket**, nicht
über das Netzwerk (TCP).

Der TestLink-Web-Installer läuft aber als PHP-Prozess innerhalb von Apache (Linux-Benutzer `www-data`) und
verbindet sich über **TCP** (`127.0.0.1:5432`) — dafür brauchen wir Passwort-Authentifizierung.

Mit `\q` verlässt du `psql` wieder.

## Schritt 3: Passwort für den Superuser `postgres` setzen

Innerhalb von `psql` (oder direkt per `-c`, wie hier):

```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'DeinStarkesPasswort123!';"
```

Wähle ein eigenes, starkes Passwort — merke es dir gut (Passwortmanager), du brauchst es gleich im
Web-Installer.

> **Sicherheitshinweis:** Ein Passwort direkt im Terminal-Befehl landet in deiner Shell-History
> (`~/.bash_history`). Für eine Demo ist das akzeptabel; für Prod solltest du entweder `\password postgres`
> interaktiv innerhalb von `psql` verwenden (landet nicht in der History) oder die History für sensible
> Befehle bereinigen.

## Schritt 4: `pg_hba.conf` verstehen — die Zugriffssteuerung von PostgreSQL

`pg_hba.conf` (**h**ost-**b**ased **a**uthentication) legt fest, **wer sich von wo aus wie** verbinden darf.
Sie liegt unter:

```bash
sudo find /etc/postgresql -name pg_hba.conf
# typischerweise: /etc/postgresql/17/main/pg_hba.conf
```

Öffne sie zum Ansehen:

```bash
sudo cat /etc/postgresql/17/main/pg_hba.conf
```

Die relevanten (unkommentierten) Standard-Zeilen sehen etwa so aus:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
```

Spaltenweise erklärt:

- **TYPE**: `local` = Verbindung über Unix-Socket (kein Netzwerk), `host` = Verbindung über TCP/IP.
- **DATABASE**: für welche Datenbank(en) die Regel gilt (`all` = alle).
- **USER**: für welche Rolle(n) die Regel gilt (`all` = alle).
- **ADDRESS**: nur bei `host`-Zeilen relevant — von welchem Netzwerk/welcher IP aus (`127.0.0.1/32` =
  ausschließlich von der Maschine selbst, über die lokale Loopback-Adresse).
- **METHOD**: die Authentifizierungsmethode — `peer` (siehe oben, nur für `local`), `scram-sha-256`
  (moderne, sichere Passwort-Authentifizierung, seit PostgreSQL 13 Standard) oder das ältere `md5`.

**Die gute Nachricht:** Auf einer frischen Debian-Installation ist die `host ... 127.0.0.1/32
scram-sha-256`-Zeile bereits vorhanden — TCP-Passwort-Login von der eigenen Maschine aus funktioniert also
in der Regel bereits ohne Änderung. Prüfe es trotzdem explizit (nächster Schritt), statt dich blind darauf
zu verlassen — Konfigurationsdateien werden manchmal von vorherigen Installationen/Admins abweichend
gepflegt.

PostgreSQL liest Regeln **von oben nach unten** und wendet die **erste passende** Zeile an — die
Reihenfolge ist also relevant, falls du später eigene, speziellere Regeln ergänzt (die sollten dann *vor*
den allgemeinen `all/all`-Zeilen stehen).

## Schritt 5: TCP-Verbindung mit Passwort testen

```bash
psql -h 127.0.0.1 -U postgres
```

`-h 127.0.0.1` erzwingt eine **TCP**-Verbindung (statt des Unix-Sockets) — dadurch greift nicht mehr
`peer`, sondern die `host`-Zeile aus `pg_hba.conf`, und du wirst nach dem Passwort gefragt, das du in
Schritt 3 gesetzt hast. Kommst du rein, siehst du den Prompt `postgres=#`. Mit `\conninfo` kannst du dir
die aktive Verbindung anzeigen lassen, mit `\q` wieder verlassen.

**Falls die Verbindung abgelehnt wird** ("no pg_hba.conf entry"): Die passende `host`-Zeile fehlt oder
wurde geändert. Ergänze sie:

```bash
echo "host    all             all             127.0.0.1/32            scram-sha-256" | sudo tee -a /etc/postgresql/17/main/pg_hba.conf
```

`tee -a` hängt an (append), statt zu überschreiben. Danach **muss** PostgreSQL neu gestartet werden, damit
die geänderte `pg_hba.conf` gilt:

```bash
sudo systemctl restart postgresql
```

## Schritt 6: `listen_addresses` prüfen

PostgreSQL muss überhaupt auf einer Netzwerkschnittstelle lauschen, damit TCP-Verbindungen ankommen:

```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
```

Der Standardwert ist `localhost` — das reicht für unseren Fall (Apache/PHP verbinden sich von derselben
Maschine aus). Nur falls du PostgreSQL später auf einem **eigenen** Server betreibst (siehe
[Kapitel 9](09-hardening-and-prod.md)), musst du das anpassen (`postgresql.conf`, Zeile
`listen_addresses = '...'`, plus passende `pg_hba.conf`-Regel für die IP des Webservers statt `127.0.0.1`).

## Was du gelernt hast

- PostgreSQL kennt nur **Rollen** — sowohl für Login-Benutzer als auch für Gruppen.
- `peer`-Authentifizierung vertraut dem Linux-Benutzernamen, funktioniert aber nur lokal über den
  Unix-Socket — nicht über TCP/Netzwerk.
- `pg_hba.conf` steuert Zugriff zeilenweise nach Verbindungstyp, Datenbank, Rolle, Adresse und
  Auth-Methode — von oben nach unten, erste passende Regel gewinnt.
- Nach Änderungen an `pg_hba.conf` braucht PostgreSQL einen `restart` (bzw. mindestens `reload`), damit die
  Änderung wirkt.
- `listen_addresses` bestimmt, auf welchen Netzwerkschnittstellen PostgreSQL überhaupt lauscht.

## Verständnis-Check

1. Warum funktioniert `sudo -u postgres psql` ohne Passwort, aber `psql -h 127.0.0.1 -U postgres` fragt
   nach einem?
2. Was bedeutet die Adresse `127.0.0.1/32` in einer `pg_hba.conf`-Zeile konkret (was lässt sie zu, was
   nicht)?
3. Angenommen, du fügst eine neue, speziellere Regel **unterhalb** der bestehenden `all/all`-Zeile ein —
   wird sie greifen? Warum (nicht)?

Weiter mit [Kapitel 5: TestLink-Quellcode holen](05-testlink-source.md).
