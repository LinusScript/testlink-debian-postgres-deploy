# 0 – Proxmox VE: Debian-13-VM erstellen

## Ziel dieses Kapitels

Eine frische Debian-13-VM auf deinem Proxmox-VE-Host, die per SSH erreichbar ist und auf der wir ab
Kapitel 1 weiterarbeiten.

## Konzepte, die du hier lernst

- Was ein **Hypervisor** (Proxmox VE) macht: Er teilt die Hardware eines physischen Servers in mehrere
  unabhängige virtuelle Maschinen (VMs) auf. Jede VM verhält sich wie ein eigener Computer mit eigener
  virtueller CPU, eigenem RAM, eigener Festplatte.
- **ISO-Image**: eine 1:1-Kopie einer Installations-CD/DVD als Datei — Proxmox "legt" diese Datei virtuell
  ins CD-Laufwerk der VM, damit der Debian-Installer booten kann.
- **virtio**: paravirtualisierte Treiber (Netzwerk/Festplatte), die deutlich schneller sind als emulierte
  Standard-Hardware, weil Gast und Host direkter kommunizieren als bei "echter" emulierter Hardware.

## Schritt 1: Debian-13-ISO herunterladen

Auf deinem Proxmox-Host (Weboberfläche, meist `https://<pve-ip>:8006`):

1. Im linken Baum: dein **Storage** auswählen, das ISOs speichern kann (oft `local`).
2. Reiter **ISO Images** → **Download from URL** (oder manuell hochladen, falls dein PVE das nicht anbietet).
3. URL der offiziellen Debian-13-netinst-ISO eintragen (die genaue Datei/URL prüfst du selbst unter
   `https://www.debian.org/distrib/netinst` — die Version ändert sich mit jedem Debian-Patchlevel, deswegen
   hier bewusst kein fest verdrahteter Link).
4. **netinst** reicht völlig — sie lädt beim Installieren nur die Pakete nach, die du wirklich brauchst,
   das spart Platz gegenüber dem großen DVD-Image.

> **Warum netinst und nicht die Desktop-Version?** Wir bauen einen Server ohne grafische Oberfläche.
> Alles, was wir brauchen (Apache, PHP, PostgreSQL), läuft über die Kommandozeile.

## Schritt 2: VM anlegen

Oben rechts in der Proxmox-Oberfläche: **Create VM**. Der Assistent hat mehrere Reiter:

| Reiter | Einstellung | Warum |
|---|---|---|
| **General** | Name z. B. `testlink-demo`, VM-ID frei wählen | Eindeutiger Name/ID zur Wiedererkennung |
| **OS** | ISO Image = die eben hochgeladene Debian-13-ISO, Type = `Linux`, Version = `6.x - 2.6 Kernel` | Proxmox stellt darauf abgestimmte virtuelle Hardware/Treiber ein |
| **System** | BIOS: `Default (SeaBIOS)` reicht für eine Demo (UEFI nur nötig, falls du Secure Boot brauchst); Qemu Agent: **aktivieren** | Der QEMU-Guest-Agent erlaubt Proxmox später sauberes Herunterfahren/Status-Infos aus der VM |
| **Disks** | Bus/Device: `VirtIO Block` oder `SCSI` mit Controller `VirtIO SCSI single`, Größe: **20 GB** | 20 GB reicht für OS + Apache/PHP/PostgreSQL + TestLink-Uploads bei einer Demo bequem |
| **CPU** | 2 Cores | TestLink + PostgreSQL + Apache sind für eine Demo mit 2 Cores gut bedient |
| **Memory** | 2048 MB (2 GB) | Ausreichend für alle drei Dienste parallel; bei spürbarer Trägheit später erhöhen |
| **Network** | Bridge `vmbr0` (Standard-Bridge deines PVE-Hosts), Model `VirtIO (paravirtualized)` | VirtIO-Netzwerktreiber sind schneller als emulierte e1000-Karten |

Am Ende: **Confirm** → VM ist angelegt, aber noch nicht gestartet.

> **Warum diese Werte und nicht mehr?** Du kannst CPU/RAM/Disk jederzeit später erhöhen (VM stoppen,
> Werte in **Hardware** anpassen, wieder starten). Klein anfangen und bei Bedarf skalieren ist der übliche
> Weg — auch später in Prod.

## Schritt 3: VM starten und Debian installieren

1. VM auswählen → **Start**, dann **Console** öffnen (im Browser über noVNC).
2. Der Debian-Installer bootet. Wähle **Install** (die textbasierte Variante reicht, kein
   "Graphical Install" nötig).
3. Sprache/Standort/Tastaturlayout nach deinem Geschmack (Doku hier bewusst auf Deutsch, du kannst die
   VM auf Englisch installieren, das ändert nichts an den folgenden Kapiteln).
4. **Hostname**: z. B. `testlink-demo`. **Domain**: kannst du leer lassen.
5. **Root-Passwort**: setzen (merken — brauchst du gleich für den ersten Login).
6. **Benutzer anlegen**: einen normalen Benutzer für dich selbst anlegen (z. B. deinen Namen) — arbeite
   nicht dauerhaft als `root`, sondern nutze `sudo` (mehr dazu in Kapitel 1).
7. **Partitionierung**: „Geführt – gesamte Festplatte verwenden" wählen, „Alle Dateien in eine Partition"
   — für eine Demo-VM unkompliziert und ausreichend.
8. **Softwareauswahl** (wichtigster Schritt!): Hier **nur** ankreuzen:
   - `SSH server`
   - `standard system utilities`

   **Nichts anderes** (kein "Debian desktop environment", kein "print server" o. ä.) — wir wollen
   einen schlanken Server, alle weiteren Pakete (Apache, PHP, PostgreSQL) installieren wir gezielt selbst
   und verstehen dabei, was wir installieren.
9. GRUB-Bootloader auf die (einzige) virtuelle Festplatte installieren lassen.
10. Installation abschließen → VM startet neu.

## Schritt 4: IP-Adresse ermitteln und per SSH verbinden

In der Proxmox-Konsole der VM, nach dem Login mit deinem angelegten Benutzer:

```bash
ip a
```

Suche die IP-Adresse deiner Netzwerkschnittstelle (meist `enp0s18`, `ens18` o. ä., **nicht** `lo` — das ist
die lokale Loopback-Adresse `127.0.0.1`, mit der du dich nicht von außen verbinden kannst).

Von deinem eigenen Rechner (nicht mehr über die Proxmox-Konsole) aus:

```bash
ssh <dein-benutzername>@<ip-der-vm>
```

> **Warum jetzt auf SSH umsteigen und nicht in der Proxmox-Konsole weiterarbeiten?** Copy-Paste, Scrollback
> und Tab-Vervollständigung funktionieren über eine echte SSH-Verbindung deutlich besser als über die
> browserbasierte noVNC-Konsole. Außerdem arbeitest du auf einem Produktivserver später ausschließlich
> per SSH — das gewöhnst du dir am besten direkt an.

## Was du gelernt hast

- Ein Hypervisor (Proxmox VE) virtualisiert Hardware, sodass eine VM sich wie ein eigener Rechner verhält.
- Eine minimale Server-Installation (nur SSH + Standardwerkzeuge) ist bewusst schlank, damit du jede
  weitere Software gezielt und mit Verständnis installierst.
- `ip a` zeigt dir die Netzwerkschnittstellen und deren Adressen; `lo` ist immer die lokale Loopback-Adresse.
- SSH ist ab jetzt dein Haupt-Zugangsweg zur VM — genau wie später auf einem echten Produktivserver.

## Verständnis-Check

1. Was ist der Unterschied zwischen der ISO-Datei und der fertig installierten VM?
2. Warum installieren wir Apache/PHP/PostgreSQL nicht schon während der Debian-Installation mit?
3. Was passiert, wenn du dich per `ssh <user>@127.0.0.1` von deinem eigenen Rechner aus verbinden willst
   (Tipp: wessen `127.0.0.1` ist das)?

Weiter mit [Kapitel 1: Linux-Grundlagen für dieses Projekt](01-linux-basics.md).
