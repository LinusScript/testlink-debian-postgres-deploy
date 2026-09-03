# Was sind Linux und Debian?

## Kurzfassung

**Linux** ist der Kernel (Kern) eines Betriebssystems — die Software-Schicht, die Prozessor, Speicher,
Festplatten und Netzwerk verwaltet. **Debian** ist eine vollständige, gebrauchsfertige
**Linux-Distribution**: Linux-Kernel plus Paketverwaltung, Systemprogramme und tausende fertig
gepackte Software-Pakete. In unserem Stack ist Debian das Betriebssystem, auf dem alles andere aufbaut.

## Geschichte (kurz)

Linux wurde 1991 von **Linus Torvalds**, damals Student in Helsinki, als freies Betriebssystem-Kernel-
Projekt gestartet — motiviert durch Unzufriedenheit mit den verfügbaren Alternativen und als
Lernprojekt. Er veröffentlichte den Quellcode frei, woraufhin sich weltweit Entwickler an der
Weiterentwicklung beteiligten — bis heute eines der größten kollaborativen Software-Projekte überhaupt.

**Debian** wurde 1993 von **Ian Murdock** gegründet — der Name ist ein Kofferwort aus seinem eigenen
Vornamen und dem seiner damaligen Partnerin Debra ("Deb" + "Ian"). Debian war früh bekannt für seinen
Fokus auf **Stabilität** und eine strikte **Free-Software-Philosophie** (Debian Free Software Guidelines)
— beides Gründe, warum Debian bis heute besonders häufig auf Servern eingesetzt wird, wo Verlässlichkeit
wichtiger ist als die allerneuesten Softwareversionen.

**Warum das für dich relevant ist:** Debians Stabilitäts-Fokus erklärt einige Entscheidungen aus unserem
Projekt — z. B., warum Debian 13 "Trixie" bewusst mit etwas älteren, aber gut getesteten
Paketversionen ausgeliefert wird, statt immer die brandneueste Version jeder Software mitzubringen.

## Kernkonzept

Ein Betriebssystem besteht aus mehreren Schichten:

```
Anwendungen (TestLink, Apache, PostgreSQL, ...)
       ↓
Distribution (Debian): Paketverwaltung, Systemprogramme, Konfigurationsstandards
       ↓
Linux-Kernel: verwaltet Prozessorzeit, Speicher, Geräte, Dateisysteme, Netzwerk
       ↓
Hardware (bzw. bei uns: virtuelle Hardware von Proxmox VE)
```

Wichtig: "Linux" allein ist **kein** installierbares Betriebssystem — es ist immer eine Distribution
(Debian, Ubuntu, Fedora, ...), die den Kernel gebrauchsfertig macht.

## Wofür wird es verwendet

Allgemein: Linux-Distributionen dominieren den Server- und Cloud-Bereich (und stecken z. B. auch in
Android, das auf dem Linux-Kernel basiert). Debian speziell ist eine der ältesten und am direktesten
community-getragenen Distributionen — viele andere Distributionen (u. a. Ubuntu) bauen selbst wieder auf
Debian auf.

In unserem Kontext: Debian 13 ("Trixie") ist das Betriebssystem unserer Demo-VM und des Zielservers —
es liefert PHP, Apache, PostgreSQL und MariaDB als fertige, aufeinander abgestimmte Pakete.

## Wichtige Begriffe

- **Kernel** — der Betriebssystem-Kern (Linux selbst).
- **Distribution** — Kernel + Paketverwaltung + Systemprogramme, gebrauchsfertig kombiniert (Debian).
- **`apt`/`dpkg`** — Debians Paketverwaltung (siehe Kapitel 1 im Lernpfad).
- **`systemd`** — Debians Init-System, verwaltet alle Dienste (Apache, PostgreSQL, SSH, ...).
- **Root** — der administrative Superuser (UID 0); `/` (Wurzelverzeichnis) ist etwas anderes als der
  Benutzer `root` — Details siehe verlinkter Lernpfad unten.

## Die wichtigsten Befehle

```bash
uname -r                 # Kernel-Version anzeigen
cat /etc/os-release        # installierte Distribution + Version anzeigen
sudo apt-get update          # Paketlisten aktualisieren
sudo apt-get install -y <paket>   # ein Paket installieren
sudo systemctl status <dienst>     # Status eines Dienstes prüfen
```

## Für die Tiefe: eigener Lernpfad

Linux/Debian-Grundlagen so ausführlich zu behandeln wie PHP/Apache/PostgreSQL hier würde den Rahmen
dieses TestLink-Repos sprengen — dafür gibt es einen eigenen, dedizierten Lernpfad:
**[Linux-Profi-Wiki](https://linusscript.github.io/linux-profi-wiki/)** — dort lernst du Linux/Debian
systematisch von Grund auf (Dateisystem, Benutzer/Rechte, Paketverwaltung, Prozesse, Netzwerk,
Bash-Skripting), unabhängig von diesem konkreten TestLink-Projekt.

## Bezug zu unserem Projekt

- [Kapitel 0](../tutorial/00-proxmox-vm.md) — die Debian-VM in Proxmox erstellen
- [Kapitel 1](../tutorial/01-linux-basics.md) — die Linux-Grundlagen, die du für den Rest des
  Lernpfads brauchst
