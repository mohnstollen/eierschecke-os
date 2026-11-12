# Eierschecke-Theme für jedes Xfce

Das Aussehen von EierscheckeOS – dunkles Anthrazit mit goldgelbem Akzent – lässt sich auch auf
anderen Xfce-Systemen einrichten (Debian, Ubuntu/Xubuntu, Linux Mint, MX Linux, Fedora, Arch …).
Das Skript `install.sh` holt sich alles aus diesem Repo; es gibt keine zweite Kopie der Grafiken.

## Was eingerichtet wird

| Bestandteil | Umsetzung | Ort |
|---|---|---|
| GTK- und Fenster-Theme | Orchis-Dark, mit Akzent `#e8b84a` aus dem Quelltext gebaut | `~/.themes/Eierschecke-Dark` |
| Icons | Papirus-Dark mit gelben Ordnern | systemweit (Paket) |
| Schriften | Inter (Oberfläche), JetBrains Mono (Terminal) | systemweit (Pakete) |
| Hintergrundbilder | vier Motive, 1920 × 1080 | `~/.local/share/backgrounds/eierschecke` |
| Terminal | dunkles Farbschema für xfce4-terminal | Xfce-Einstellungen |
| Logo | als Icon `eierschecke-logo` | `~/.local/share/icons` |
| Panel *(optional)* | unten, Whisker-Menü mit Logo, Fensterknöpfe, Tray, Uhr | `--panel` |
| Boot-Animation, GRUB, Anmeldung *(optional)* | Plymouth-Theme, GRUB-Theme, LightDM | `--system` |

## Installation

Repo holen und das Skript als normaler Benutzer in einer laufenden Xfce-Sitzung starten:

```bash
git clone https://github.com/mohnstollen/eierschecke-os.git
```

```bash
cd eierschecke-os
```

```bash
./theme/install.sh
```

Das Skript fragt per `sudo` nach dem Passwort, um fehlende Pakete zu installieren (`git`, `sassc`,
`rsvg-convert`, Papirus-Icons, die beiden Schriften) und die Papirus-Ordner gelb zu färben. Alles
andere landet im eigenen Benutzerkonto.

### Schalter

| Aufruf | Wirkung |
|---|---|
| `./theme/install.sh` | Theme, Icons, Schriften, Hintergrundbild, Terminalfarben |
| `./theme/install.sh --panel` | zusätzlich die Panel-Anordnung von EierscheckeOS (ersetzt das bisherige Panel) |
| `./theme/install.sh --system` | zusätzlich Boot-Animation, GRUB-Theme und Anmeldebildschirm – nur Debian, Ubuntu, Mint, MX |
| `./theme/install.sh --ohne-pakete` | nichts über die Paketverwaltung installieren |
| `./theme/install.sh --entfernen` | vorherige Xfce-Einstellungen und das vorherige Panel wiederherstellen |

Die Schalter lassen sich kombinieren, z. B. `./theme/install.sh --panel --system`.

Für `--panel` müssen das Whisker-Menü und das PulseAudio-Plugin installiert sein
(Debian/Ubuntu: `xfce4-whiskermenu-plugin`, `xfce4-pulseaudio-plugin`).

## Rückgängig machen

```bash
./theme/install.sh --entfernen
```

Das stellt die Xfce-Einstellungen so wieder her, wie sie vor dem ersten Lauf waren, und löscht
Theme und Hintergrundbilder aus dem Benutzerkonto. Die installierten Pakete (Papirus, Schriften)
bleiben, ebenso die gelben Ordner.

Was `--system` eingerichtet hat, wird von Hand zurückgestellt:

```bash
sudo plymouth-set-default-theme -R bgrt
```

```bash
sudo rm /etc/default/grub.d/eierschecke-theme.cfg && sudo update-grub
```

```bash
sudo mv /etc/lightdm/lightdm-gtk-greeter.conf.vorher /etc/lightdm/lightdm-gtk-greeter.conf
```

(`bgrt` ist das Standard-Theme von Debian; welche Plymouth-Themes es gibt, zeigt
`plymouth-set-default-theme --list`.)

## Gut zu wissen

- **Getestet** ist bisher das Aussehen im EierscheckeOS-ISO selbst sowie der Ablauf des Skripts
  (Theme-Bau, Setzen und Wiederherstellen der Einstellungen). Auf anderen Distributionen ist es
  noch nicht ausprobiert – Rückmeldungen sind willkommen.
- **xfce4-terminal** übernimmt die Farben ab Version 1.1 (Xfce 4.18 und neuer). Ältere Versionen
  speichern ihre Einstellungen anders und bleiben unverändert.
- **GTK4-/libadwaita- und Flatpak-Programme** folgen dem dunklen Farbschema, aber nicht dem
  Akzent.
- **Mehrere Bildschirme:** Das Hintergrundbild wird für alle Bildschirme gesetzt, die Xfce schon
  kennt. Kommt später einer dazu, lässt es sich in den Schreibtisch-Einstellungen auswählen.
- **Conky-Widget und Update-Center** gehören nicht zum Theme; sie stecken in `conky/` und `tools/`.
- Das GTK-Theme basiert auf [Orchis](https://github.com/vinceliuice/Orchis-theme) (GPL-3.0), die
  Icons auf [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
