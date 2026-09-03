# Was ist Apache (Apache HTTP Server)?

## Kurzfassung

Apache ist ein **Webserver** — ein Programm, das auf einem festgelegten Netzwerk-Port (meist 80 für
HTTP, 443 für HTTPS) auf eingehende Anfragen von Browsern wartet und Inhalte zurückliefert. In unserem
Stack ist er die "Eingangstür" zu TestLink.

## Geschichte

Anfang 1995 war der meistgenutzte Webserver der Welt der **NCSA HTTPd**, entwickelt von Rob McCool am
National Center for Supercomputing Applications. Als die Weiterentwicklung dort ins Stocken geriet,
sammelte eine Gruppe von Entwicklern die im Umlauf befindlichen inoffiziellen Patches/Bugfixes für NCSA
HTTPd und veröffentlichte im April 1995 daraus eine eigene, gepflegte Version. Innerhalb weniger als
eines Jahres überholte Apache NCSA HTTPd als meistgenutzten Webserver im Internet — eine Position, die
er über Jahrzehnte maßgeblich mitbestimmte.

Zum Namen kursieren zwei Erklärungen: Die **Apache Software Foundation** selbst sagt, der Name sei aus
Respekt vor dem nordamerikanischen Volk der Apache gewählt worden, bekannt für Ausdauer und
Kriegsführungs-Geschick. Eine ältere, populäre (aber von der Foundation nicht offiziell bestätigte)
Version besagt, der Name sei ein Wortspiel gewesen: "a patchy server" (ein aus Patches zusammengesetzter
Server) — weil die erste Version eben genau das war.

**Warum das für dich relevant ist:** Apache ist selbst über 30 Jahre alt und extrem modular gewachsen
(daher das Modul-System aus Kapitel 2, `a2enmod`/`a2dismod`) — jedes neue Feature (SSL, PHP-Unterstützung,
URL-Umschreibung) kam über Jahre als eigenes, zuschaltbares Modul dazu, statt den Kern ständig neu zu
schreiben. Das prägt bis heute, wie man Apache konfiguriert.

## Kernkonzept: Anfrage entgegennehmen, Antwort zurückschicken

```
Browser  →  HTTP-Anfrage (z.B. "GET /index.php")  →  Apache
Apache   →  entscheidet: statische Datei direkt ausliefern,
             ODER an einen Interpreter (PHP) weiterreichen  →  erzeugt Antwort
Apache   →  HTTP-Antwort (HTML, Status-Code, Header)         →  Browser
```

Apache selbst "versteht" kein PHP — es erkennt nur (über das `mod_php`-Modul, siehe
[php.md](php.md)), dass eine `.php`-Datei angefragt wurde, und reicht die Ausführung an den
eingebetteten PHP-Interpreter weiter.

## Wofür wird es verwendet

Allgemein: als Webserver für praktisch jede Art von Website/Web-Anwendung — von einfachen HTML-Seiten
bis zu komplexen PHP-Anwendungen wie TestLink. Alternativen: nginx (moderner, oft für sehr hohe Lasten
bevorzugt), Caddy (automatisches HTTPS).

In unserem Kontext: Apache liefert die TestLink-Oberfläche aus, reicht `.php`-Aufrufe an PHP weiter, und
trennt über **VirtualHosts** (siehe [Kapitel 6](../installation/06-virtualhost.md)) verschiedene Websites
auf demselben Server voneinander.

## Wichtige Begriffe

- **VirtualHost** — eine in sich abgeschlossene Website-Konfiguration (eigener `DocumentRoot`, eigener
  Hostname) — ein Apache-Prozess kann mehrere davon parallel bedienen.
- **DocumentRoot** — das Verzeichnis auf der Festplatte, aus dem ein VirtualHost Dateien ausliefert.
- **MPM (Multi-Processing Module)** — bestimmt, *wie* Apache mehrere gleichzeitige Anfragen bearbeitet
  (`prefork` = ein Prozess pro Anfrage, `event` = asynchron/moderner) — siehe
  [Kapitel 2](../installation/02-apache.md).
- **Modul** — zuschaltbare Zusatzfunktion (`mod_php`, `mod_rewrite`, `mod_ssl`, ...).
- **`.htaccess`** — eine Konfigurationsdatei, die *innerhalb* eines Verzeichnisses Apache-Einstellungen
  überschreiben kann, ohne die zentrale Konfiguration anzufassen (nur wirksam, wenn `AllowOverride`
  das erlaubt).

## Die wichtigsten Befehle

```bash
apache2 -v                  # installierte Version
apache2ctl configtest       # Konfiguration auf Syntaxfehler prüfen (IMMER vor einem Neustart!)
apache2ctl -M               # alle geladenen Module anzeigen
apache2ctl -S               # alle aktiven VirtualHosts anzeigen, inkl. Quelldatei

sudo a2enmod <modul>        # Modul aktivieren (Symlink setzen)
sudo a2dismod <modul>       # Modul deaktivieren
sudo a2ensite <config>      # VirtualHost aktivieren
sudo a2dissite <config>     # VirtualHost deaktivieren

sudo systemctl restart apache2   # Dienst komplett neu starten (kurzer Ausfall)
sudo systemctl reload apache2    # Konfiguration neu einlesen, ohne Verbindungen zu kappen
```

## Bezug zu unserem Projekt

- [Kapitel 2](../installation/02-apache.md) — Installation, MPM-Wechsel, warum genau dieses MPM
- [Kapitel 6](../installation/06-virtualhost.md) — VirtualHost Zeile für Zeile erklärt
- [Kapitel 8](../installation/08-verification-debugging.md) — Apache-Logs lesen, Fehler eingrenzen
