# EierscheckeOS – Spezifikation

**Version:** 1.0 „Quarkkeulchen“ · **Stand:** 10.11.2026 · **Status:** Entwurf

Eine Debian-basierte Desktop-Distribution mit Xfce, optimiert für das Lenovo ThinkPad X280. Dunkles, modernes Design mit goldgelbem Akzent, vorinstallierte Alltags- und Bastel-Software, Energiesparen ab Werk und eine einfache Update-Routine.

---

## 1. Eckdaten

| Punkt | Festlegung |
|---|---|
| Name | EierscheckeOS (intern: `eierschecke`) |
| Versionsnamen | Sächsisches Gebäck: 1.0 „Quarkkeulchen“, 2.0 „Pflaumenkuchen“, 3.0 „Christstollen“ … |
| Basis | Debian 13 „Trixie“ (stable), inkl. `contrib`, `non-free`, `non-free-firmware` |
| Architektur | amd64 |
| Zielhardware | Lenovo ThinkPad X280 (läuft auch auf anderen x86-64-Rechnern) |
| Desktop | Xfce 4 |
| Sprache / Region | Deutsch (`de_DE.UTF-8`), Tastatur `de` (nodeadkeys), Zeitzone `Europe/Berlin` |
| Auslieferung | Hybrides Live-ISO (USB-Stick/DVD), UEFI-Boot (Secure Boot über shim) |

---

## 2. Build & Repository

- **Repository:** GitHub `mohnstollen/eierschecke-os` (öffentlich)
- **Build-Werkzeug:** Debians `live-build`
- **CI:** GitHub Actions baut das ISO in einem Debian-Container
  - Auslöser: Tag-Push (`v*`) → Release; manuell per „Run workflow“ → Test-Build
  - Ergebnis: ISO + SHA256-Prüfsumme als Release-Download
- **Lokaler Build** (optional): `sudo ./build.sh` auf einem Debian-/MX-System

### Geplante Repo-Struktur

```
eierschecke-os/
├── .github/workflows/build-iso.yml
├── build.sh
├── config/
│   ├── package-lists/          # Paketlisten (*.list.chroot)
│   ├── archives/               # Fremd-Repos (Mozilla, Brave, Signal …)
│   ├── hooks/live/             # Skripte im chroot (Flatpaks, Treiber, Einstellungen)
│   ├── includes.chroot/        # Dateien ins System (etc/skel, Themes, Skripte)
│   └── bootloaders/            # GRUB-/ISOLINUX-Theme fürs Live-Medium
├── branding/                   # Logo (SVG), Wallpaper, Plymouth, GRUB, LightDM
├── calamares/                  # Installer-Konfiguration und Branding
├── conky/                      # Conky-Widgets und Abruf-Skripte
├── tools/                      # Update-Center, Conky-Menü
└── docs/
```

---

## 3. Installer & Partitionierung

- **Installer:** Calamares (grafisch), mit EierscheckeOS-Branding und Diashow
- **Verschlüsselung:** keine
- **Standard-Partitionsschema** (Option „Festplatte löschen“):

| Partition | Größe | Dateisystem | Einhängepunkt |
|---|---|---|---|
| EFI-Systempartition | 1 GB | FAT32 | `/boot/efi` |
| System | Rest | Btrfs (zstd-Kompression, `noatime`) | siehe Subvolumes |

- **Btrfs-Subvolumes:** `@` → `/`, `@home` → `/home`, `@snapshots` → `/.snapshots`, `@log` → `/var/log`, `@cache` → `/var/cache`
- **Swap:** Swap-Datei in eigenem Subvolume `@swap`, Größe = RAM, damit Ruhezustand (Hibernate) möglich ist
- **Snapshots:** Snapper und `grub-btrfs` → automatischer Snapshot vor jedem Update, Rückkehr zu älteren Ständen direkt im GRUB-Menü
- Manuelle Partitionierung bleibt im Installer möglich
- **Bei der Installation automatisch:** Benutzer in den Gruppen `sudo`, `lpadmin`, `scanner`, `dialout` (MicroPython/Thonny), `plugdev`

---

## 4. Design & Branding

### Farbschema
- Hintergrund: dunkles Anthrazit (#1e1e22 / #2a2a30)
- Akzent: warmes Goldgelb (Eiercreme), z. B. #e8b84a
- Einheitlich in GTK, Terminal, Conky, Plymouth, GRUB, LightDM und Calamares

### Desktop
- **GTK-Theme:** Orchis-Dark (Akzentfarbe angepasst), Fallback Arc-Dark
- **Fenster-Rahmen:** passendes dunkles xfwm4-Theme
- **Icons:** Papirus-Dark (Ordnerfarbe gelb)
- **Schriften:** Inter (Oberfläche), JetBrains Mono (Terminal/Code)
- **Panel:** unten, mit Whisker-Menü (EierscheckeOS-Logo), Fensterknöpfen, Tray, Akku, Lautstärke, Netzwerk, Uhr mit Kalender
- **Terminal:** dunkles Farbschema, optional Dropdown-Modus per F12
- Alle Voreinstellungen über `/etc/skel` und damit für jeden neuen Benutzer gültig

### Branding-Elemente
- **Logo:** flach gezeichnetes Eierschecke-Stück im Querschnitt (Boden, Quark, Eiercreme), als SVG
- **Boot-Animation (Plymouth):** Die Eierschecke baut sich Schicht für Schicht auf (Hefeteig → Quark → Eiercreme) und dient so als Ladeanzeige. Zum Abschluss bräunt die Oberfläche goldgelb.
- **GRUB-Menü:** dunkles Theme mit Logo
- **Login (LightDM GTK Greeter):** dunkel, mit Logo und unscharfem Hintergrund
- **Hintergrundbilder:** 3–5 eigene dunkle Wallpaper; Wechsel über Variety

---

## 5. Conky-Desktop-Widget

- Halbtransparentes Widget rechts oben im EierscheckeOS-Farbschema
- **Wetter:** Herzogenaurach (49,57° N, 10,88° O)
  - Aktuell: Temperatur, gefühlte Temperatur, Wetterlage (Symbol), Wind, Luftfeuchte
  - Vorhersage für 3 Tage: Min/Max, Symbol, Regenwahrscheinlichkeit
  - Datenquelle: Open-Meteo (kostenlos, ohne API-Key), Aktualisierung alle 30 Minuten
- **Tagesschau:** 6–8 aktuelle Schlagzeilen aus dem offiziellen RSS-Feed, Aktualisierung alle 15 Minuten
- **System (optional):** Akku, CPU, RAM, Datenträger
- **Offline-fest:** Die Daten werden zwischengespeichert, ohne Netz bleiben die letzten Werte stehen
- **Konfiguration:** `~/.config/eierschecke/conky.conf` (Ort, Intervalle, Anzahl Schlagzeilen)
- **Verwaltung:** eigenes kleines Menü „Desktop-Widgets“ (Widgets an/aus, Ort ändern, neu starten); zusätzlich Conky Manager 2 optional

---

## 6. Vorinstallierte Anwendungen

Quelle: **D** = Debian-Paket · **R** = offizielles Hersteller-Repo · **F** = Flatpak (Flathub) · **E** = Eigenentwicklung

### Büro & Internet
| Zweck | Anwendung | Quelle |
|---|---|---|
| Office | LibreOffice (deutsch, Rechtschreibung, Hilfe) | D |
| Browser | Firefox (aktuell, aus dem Mozilla-Repo) | R |
| Browser | Brave | R |
| E-Mail | Thunderbird | D |
| RSS mit Sync | NewsFlash | F |
| Torrent | Transmission (GTK) | D |
| Mediatheken | MediathekView | F |

### Kommunikation
| Zweck | Anwendung | Quelle |
|---|---|---|
| Messenger | Signal Desktop | R |
| Messenger | Telegram Desktop | F |
| KI-Assistent | Claude Desktop (Linux-Beta) | R |

### Dateien, Sync & Medien
| Zweck | Anwendung | Quelle |
|---|---|---|
| Dateimanager | Thunar mit Archiv-, Medien-Tags- und Freigabe-Plugin, gvfs-Backends (SMB/SFTP) | D |
| Synchronisation | Syncthing + Syncthing Tray | R / D |
| eBook-Verwaltung | Calibre | D |
| eBook-Reader | Foliate | D |
| Podcasts | Kasts (Sync mit AntennaPod über gPodder-API) | F |

### Entwicklung & Basteln
| Zweck | Anwendung | Quelle |
|---|---|---|
| Code-Editor | VSCodium | R |
| Leichter Editor/IDE | Geany (mit Plugins) | D |
| Python/MicroPython | Thonny | D |
| Markdown | Apostrophe | F |
| Terminal | xfce4-terminal | D |
| 3D-Druck | OrcaSlicer | F |
| Werkzeuge | git, curl, wget, htop, btop, ncdu, jq, python3-pip, build-essential | D |

### System
| Zweck | Anwendung | Quelle |
|---|---|---|
| Energie | TLP + TLP-UI, xfce4-power-manager, powertop | D / F |
| Updates | EierscheckeOS Update-Center | E |
| Flatpak-Verwaltung | Warehouse | F |
| Paketverwaltung | Synaptic | D |
| Hintergrundbilder | Variety | D |
| Desktop-Widgets | Conky (`conky-all`) + Widget-Menü | D / E |
| Snapshots | Snapper + snapper-gui, grub-btrfs | D |

### Paketformate
- **Flatpak** mit Flathub vorkonfiguriert, Integration in Thunar/Menü
- **Snap:** installierbar, standardmäßig **deaktiviert** (Aktivierung per Knopf im Update-Center), weil `snapd` einen eigenen Hintergrunddienst braucht

---

## 7. Drucker & Scanner

| Gerät | Funktion | Treiber/Software | Quelle |
|---|---|---|---|
| Samsung ML-1640 | Drucken | `printer-driver-splix` (Fallback: Samsung ULD von HP) | D |
| Brother DCP-7030 | Drucken | `printer-driver-brlaser` | D |
| Brother DCP-7030 | Scannen | `brscan3` (SANE-Treiber) | Brother |
| Brother DCP-7030 | Scan-Taste am Gerät | `brscan-skey` | Brother |

- **Basis:** CUPS, system-config-printer, `printer-driver-all`, ipp-usb, SANE
- **Scan-Programme:** gscan2pdf (mehrseitige PDFs), Simple Scan (schnelle Scans)
- **Texterkennung:** Tesseract mit Sprachpaketen Deutsch und Englisch (in gscan2pdf eingebunden), OCRmyPDF inklusive Thunar-Rechtsklick „PDF durchsuchbar machen“
- Brother-Pakete werden beim Build bzw. bei der Installation direkt von Brother geladen (keine Weiterverteilung im ISO)

---

## 8. Energiemanagement

- **TLP** mit ThinkPad-Profil:
  - Akku-Ladeschwellen 75 % Start / 80 % Stopp (umschaltbar auf 100 % für unterwegs)
  - CPU: `powersave` mit Energy-Performance-Preference `balance_power` im Akkubetrieb
  - PCIe-ASPM, WLAN-Energiesparen, USB-Autosuspend (Eingabegeräte ausgenommen), Audio-Energiesparen
- **xfce4-power-manager:** Bildschirm dimmen und abschalten, Standby bei Inaktivität, Deckel zu = Standby
- **Ruhezustand** über die Swap-Datei
- `power-profiles-daemon` wird nicht installiert (Konflikt mit TLP)
- **powertop** zur Analyse; keine pauschale Auto-Tune-Einstellung, um Konflikte mit TLP zu vermeiden
- `thermald` für die Intel-CPU

---

## 9. Update-Routine

- **Automatisch im Hintergrund:** `unattended-upgrades` installiert Debian-Sicherheitsupdates täglich
- **EierscheckeOS Update-Center (E):**
  - Tray-Symbol prüft regelmäßig auf Updates und zeigt deren Anzahl an
  - Ein Klick aktualisiert alles in einem Durchgang: Debian-Pakete, Fremd-Repos, Flatpaks und (falls aktiv) Snaps
  - Fortschrittsanzeige und Protokoll, Hinweis bei nötigem Neustart
  - Vor jedem Update automatisch ein Btrfs-Snapshot
- **Flatpak:** zusätzlich ein systemd-Timer für automatische Updates (einstellbar)
- **Distro-eigene Pakete** (Themes, Skripte, Branding) kommen später als `.deb` über ein eigenes APT-Repo auf GitHub Pages

---

## 10. ThinkPad-X280-Unterstützung

| Bereich | Umsetzung |
|---|---|
| WLAN / Bluetooth | `firmware-iwlwifi`, `firmware-misc-nonfree`, Blueman |
| Grafik | Intel UHD 620 über i915 (Mesa, `intel-media-va-driver` für Videobeschleunigung) |
| Audio | `firmware-sof-signed`, PipeWire mit WirePlumber |
| CPU-Microcode | `intel-microcode` |
| Fingerabdruckleser | fprintd (sofern vom Sensor unterstützt) |
| Firmware-Updates | `fwupd` (BIOS/Firmware über LVFS) |

### Funktionstasten (Prüfliste)
| Taste | Funktion | Zuständig |
|---|---|---|
| Fn+F1 | Lautsprecher stumm | xfce4-pulseaudio-plugin |
| Fn+F2 / F3 | Lautstärke − / + | xfce4-pulseaudio-plugin |
| Fn+F4 | Mikrofon stumm inkl. LED | PipeWire + ALSA-LED-Trigger (prüfen) |
| Fn+F5 / F6 | Helligkeit − / + | xfce4-power-manager |
| Fn+F7 | Bildschirm umschalten | Xfce-Anzeigeeinstellungen |
| Fn+F8 | Flugmodus | rfkill / NetworkManager |
| Fn+F9–F12 | Einstellungen, Suche, Fensterübersicht, Dateien | eigene Xfce-Tastenkürzel |
| Fn+Leertaste | Tastaturbeleuchtung (falls vorhanden) | Firmware |
| Fn+Esc | Fn-Lock | Firmware (LED prüfen) |
| TrackPoint / Mitteltaste | Scrollen mit Mitteltaste | libinput |

---

## 11. Begleitdienste auf dem Homeserver (optional)

Nicht Teil des ISOs, aber auf die Desktop-Apps abgestimmt; `docker-compose.yml` wird separat geliefert.

| Dienst | Zweck | Client auf EierscheckeOS | Client Android |
|---|---|---|---|
| FreshRSS | RSS-Feeds mit Sync (Nachfolger von TT-RSS, Umzug per OPML) | NewsFlash | z. B. Read You, Capy Reader |
| oPodSync | Podcast-Sync (gPodder-API) | Kasts | AntennaPod |

---

## 12. Offene Punkte & Hinweise

- [x] Leeres GitHub-Repo `eierschecke-os` anlegen
- [x] Namensprüfung vor einer öffentlichen Veröffentlichung (bestehende Distributionen/Marken) – kein Konflikt
- [ ] Logo, Wallpaper und Plymouth-Animation gestalten und abstimmen
- [ ] Funktionstasten auf echter Hardware testen (v. a. Mikrofon-LED, Fn-Lock)
- [ ] Claude Desktop ist für Linux noch Beta (Computer Use dort nicht verfügbar)
- [ ] Brother-Treiber sind proprietär → Download zur Installationszeit
- [ ] Erstes Test-ISO in einer VM prüfen, danach auf dem X280

---

*EierscheckeOS – Schicht für Schicht zum Desktop.*
