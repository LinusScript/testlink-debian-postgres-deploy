# 2 – Apache von Hand installieren

## Ziel dieses Kapitels

Apache läuft, ist per systemd verwaltet, und du kannst von deinem Browser aus die Debian-Standardseite
sehen — als Beweis, dass der Webserver grundsätzlich funktioniert, bevor wir PHP/TestLink draufsetzen.

## Was macht ein Webserver überhaupt?

Ein Browser (Client) schickt eine HTTP-Anfrage an eine IP+Port (Standard: Port 80 für HTTP, 443 für HTTPS).
Ein Webserver-Prozess (hier: Apache) lauscht auf diesem Port, nimmt die Anfrage entgegen, sucht die
passende Datei (bei statischem HTML) oder reicht die Anfrage an einen Interpreter weiter (bei PHP — dazu
mehr in Kapitel 3), und schickt eine HTTP-Antwort zurück.

## Schritt 1: Apache installieren

```bash
sudo apt-get update
sudo apt-get install -y apache2
```

Nach der Installation startet und aktiviert Debian den Dienst automatisch. Prüfen:

```bash
sudo systemctl status apache2
```

Du solltest `active (running)` sehen. Im Browser: `http://<ip-deiner-vm>/` aufrufen — die Debian-
Apache-Standardseite ("Apache2 Debian Default Page") sollte erscheinen.

## Schritt 2: MPM verstehen — und warum wir es wechseln müssen

Apache verarbeitet eingehende Verbindungen über ein austauschbares **MPM** (Multi-Processing Module) —
das entscheidet, *wie* Apache mehrere gleichzeitige Anfragen bearbeitet:

- **`event`** (Debian-Standard seit vielen Jahren): asynchron, sehr performant bei vielen gleichzeitigen
  Verbindungen — aber **inkompatibel mit klassischem `mod_php`**, weil `mod_php` PHP direkt in Apaches
  Worker-Threads ausführt und dabei nicht thread-sicher ist.
- **`prefork`**: startet für jede Anfrage einen eigenen Prozess (statt Threads) — dadurch mit `mod_php`
  kompatibel, aber ressourcenhungriger bei sehr vielen gleichzeitigen Nutzern.

Welches MPM aktiv ist, prüfst du mit:

```bash
apache2ctl -M | grep mpm
```

Für unsere Demo (klassisches TestLink-Setup mit `mod_php`, siehe Kapitel 3) wechseln wir bewusst auf
`prefork`:

```bash
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork
```

`a2enmod`/`a2dismod` (**a**pache **2** **en**able/**dis**able **mod**ule) sind Debian-spezifische
Hilfsskripte, die Symlinks in `/etc/apache2/mods-enabled/` setzen bzw. entfernen, die auf die eigentlichen
Moduldefinitionen in `/etc/apache2/mods-available/` zeigen. Kontrolle:

```bash
ls -la /etc/apache2/mods-enabled/ | grep mpm
```

> **Für später (Prod):** Bei hoher Last ist PHP-FPM + MPM `event` die modernere, ressourcenschonendere
> Kombination. Das steht im Detail in [Kapitel 9](09-hardening-and-prod.md) — für den Lernpfad hier bleiben
> wir bei `prefork` + `mod_php`, weil es weniger bewegliche Teile hat und näher am klassischen,
> dokumentierten TestLink-Setup ist.

## Schritt 3: Rewrite-Modul aktivieren

TestLink nutzt (wie viele PHP-Anwendungen) `.htaccess`-Regeln, die auf `mod_rewrite` basieren
(URL-Umschreibung). Ohne das Modul würden solche Regeln stillschweigend ignoriert:

```bash
sudo a2enmod rewrite
```

## Schritt 4: Konfiguration testen und Apache neu starten

Nach **jeder** Änderung an Modulen oder Konfigurationsdateien solltest du zuerst die Syntax prüfen, bevor
du den Dienst neu startest — ein Syntaxfehler in der aktiven Konfiguration würde sonst dazu führen, dass
Apache beim Neustart gar nicht mehr hochkommt:

```bash
sudo apache2ctl configtest
```

Erwartete Ausgabe: `Syntax OK`. Erst dann:

```bash
sudo systemctl restart apache2
sudo systemctl enable apache2
```

`enable` sorgt dafür, dass Apache auch nach einem Server-Neustart automatisch wieder startet (systemd
merkt sich das über einen Symlink in `/etc/systemd/system/multi-user.target.wants/`).

## Verifikation

```bash
apache2 -v                 # installierte Apache-Version
apache2ctl -M | grep mpm   # aktives MPM (sollte jetzt prefork sein)
apache2ctl -M | grep rewrite
curl -I http://localhost/  # HTTP-Statuszeile + Header von der lokalen VM aus abrufen
```

`curl -I` schickt nur eine `HEAD`-Anfrage (ohne den Seiteninhalt herunterzuladen) — praktisch, um schnell
zu prüfen, ob und wie ein Server antwortet, ohne die ganze Seite in dein Terminal zu bekommen.

## Was du gelernt hast

- Ein Webserver nimmt HTTP-Anfragen entgegen und liefert Inhalte oder reicht sie an einen Interpreter weiter.
- Apache-MPMs bestimmen die Nebenläufigkeitsstrategie; `mod_php` erzwingt `prefork` statt des moderneren
  `event`-MPM.
- `a2enmod`/`a2dismod` verwalten Apache-Module über Symlinks zwischen `mods-available` und `mods-enabled`.
- Immer `apache2ctl configtest` **vor** einem `restart`, um einen kompletten Ausfall durch Tippfehler zu
  vermeiden.

## Verständnis-Check

1. Warum ist `mod_php` nicht mit dem `event`-MPM kompatibel?
2. Was würde passieren, wenn du `systemctl restart apache2` ausführst, ohne vorher `configtest` zu prüfen,
   und die Konfiguration einen Syntaxfehler enthält?
3. Was zeigt dir `curl -I` im Gegensatz zu einem normalen `curl http://localhost/`?

Weiter mit [Kapitel 3: PHP von Hand installieren](03-php.md).
