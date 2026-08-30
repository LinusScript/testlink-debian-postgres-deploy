# 5 – TestLink-Quellcode holen

## Ziel dieses Kapitels

Der TestLink-Quellcode liegt unter `/var/www/testlink`, gehört `www-data`, und Apache liefert das
Verzeichnis grundsätzlich aus (auch wenn der VirtualHost dafür erst in Kapitel 6 sauber eingerichtet wird).

## Warum ein bestimmter Tag statt "die neueste Version"?

Git-Repositories haben oft **Tags** — feste Markierungen an einem bestimmten Commit, meist für
Releases genutzt (z. B. `1.9.20`). Anders als der `main`/`master`-Branch, der sich ständig weiterentwickelt,
zeigt ein Tag **immer auf denselben, unveränderlichen Code-Stand** — wichtig für Reproduzierbarkeit: Wenn
du (oder später ein Kollege) denselben Tag installiert, bekommt ihr exakt denselben Code.

Bei TestLink gibt es zwei relevante Tags:

- **`1.9.20`** (Januar 2020): der letzte offizielle Release-Tag, geschrieben für PHP 7.2–7.4.
- **`1.9.20-20251208`**: ein neuerer Community-Tag desselben Projekts, der laut Änderungsprotokoll gezielt
  auf Kompatibilität mit aktuellem PHP (bis 8.5) getestet wurde.

Da Debian 13 PHP 8.4 mitbringt (prüfe mit `php -v` aus Kapitel 3), verwenden wir **`1.9.20-20251208`** —
der ältere Tag würde mit hoher Wahrscheinlichkeit an entfernten/geänderten PHP-8-Sprachfeatures scheitern.

## Schritt 1: Quellcode als Tarball herunterladen

GitHub erzeugt für jeden Tag automatisch ein Download-Archiv unter einer vorhersagbaren URL:

```bash
curl -fL https://github.com/TestLinkOpenSourceTRMS/testlink-code/archive/refs/tags/1.9.20-20251208.tar.gz \
  -o /tmp/testlink.tar.gz
```

Die `curl`-Flags:

- `-f` (fail): bei einem HTTP-Fehler (z. B. 404, falscher Tag-Name) bricht `curl` mit einem Fehlercode ab,
  statt stillschweigend eine Fehlerseite als "Erfolg" herunterzuladen.
- `-L` (location): folgt HTTP-Weiterleitungen (GitHub leitet Download-URLs häufig um).
- `-o <datei>`: speichert die Antwort in eine Datei, statt sie auf dem Bildschirm auszugeben.

## Schritt 2: Entpacken

```bash
tar -xzf /tmp/testlink.tar.gz -C /tmp
```

- `-x`: extrahieren
- `-z`: durch gzip entpacken (die Datei ist `.tar.gz`, also gzip-komprimiert)
- `-f <datei>`: welche Archivdatei
- `-C /tmp`: Zielverzeichnis, in das entpackt wird

Prüfe den Namen des entpackten Verzeichnisses (GitHub benennt es nach Repo + Tag):

```bash
ls /tmp | grep testlink-code
# z.B.: testlink-code-1.9.20-20251208
```

## Schritt 3: An den endgültigen Ort verschieben

```bash
sudo mv /tmp/testlink-code-1.9.20-20251208 /var/www/testlink
```

`/var/www/` ist unter Debian der konventionelle Ort für Web-Inhalte (dort liegt auch die
Apache-Standardseite aus Kapitel 2, `/var/www/html/`).

## Schritt 4: Besitzrechte setzen

```bash
sudo chown -R www-data:www-data /var/www/testlink
```

Wie in Kapitel 1 erklärt: Apache/PHP laufen als `www-data`. Der TestLink-Web-Installer muss gleich in
dieses Verzeichnis schreiben können (u. a. `config_db.inc.php` anlegen), außerdem legt TestLink zur
Laufzeit selbst Dateien an (`upload_area/` für Anhänge, `gui/templates_c/` für kompilierte Templates).
Ohne diesen Schritt würde der Web-Installer in Kapitel 7 mit "Permission denied"-Fehlern abbrechen.

## Verifikation

```bash
ls -la /var/www/testlink | head -20
stat -c '%U:%G %a %n' /var/www/testlink   # Besitzer:Gruppe, Rechte, Name in einer Zeile
```

Der Besitzer sollte `www-data:www-data` sein.

## Was du gelernt hast

- Git-Tags markieren einen unveränderlichen Code-Stand — wichtig für reproduzierbare Installationen.
- GitHub bietet für jeden Tag automatisch einen `.tar.gz`-Download unter einer vorhersagbaren URL an.
- `curl -fL` ist die robuste Standardkombination für Downloads per Skript: bricht bei Fehlern ab, folgt
  Weiterleitungen.
- Web-Anwendungen, deren Installer selbst Dateien schreibt (wie TestLink), brauchen von Anfang an den
  richtigen Besitzer (`www-data`) auf ihrem Verzeichnis.

## Verständnis-Check

1. Was ist der praktische Unterschied zwischen dem Download eines Tags und dem Download des `main`-Branches?
2. Was würde passieren, wenn du `chown -R www-data:www-data` vergisst und direkt zum Web-Installer gehst?
3. Warum bricht `curl` (mit `-f`) ab, wenn die Tag-URL falsch geschrieben ist, statt einfach eine
   HTML-Fehlerseite herunterzuladen?

Weiter mit [Kapitel 6: Apache-VirtualHost von Hand schreiben](06-virtualhost.md).
