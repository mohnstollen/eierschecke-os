# Eierschecke-Widget: Conky mit Wetter, Tagesschau und Systemdaten

Das Desktop-Widget von EierscheckeOS läuft auch auf anderen Linux-Desktops (Xfce, MATE, Cinnamon,
LXQt … – alles mit X11). Es zeigt rechts oben halbtransparent:

- **Wetter** für einen frei wählbaren Ort: Temperatur, gefühlte Temperatur, Wetterlage, Wind,
  Luftfeuchte und eine Vorhersage für drei Tage (Quelle: Open-Meteo, ohne Anmeldung).
- **Tagesschau:** die aktuellen Schlagzeilen aus dem offiziellen RSS-Feed.
- **System:** Akku, Prozessor, Speicher, Datenträger.

Ohne Netz bleiben die letzten Werte stehen; daneben steht jeweils der Stand.

## Installation

Als normaler Benutzer in der laufenden Desktop-Sitzung:

```bash
git clone https://github.com/mohnstollen/eierschecke-os.git
```

```bash
cd eierschecke-os
```

```bash
./conky/install.sh
```

Das Skript installiert per `sudo` nur fehlende Pakete (Conky, Python-GTK, Schriften). Alles andere
landet im eigenen Benutzerkonto; das Widget startet sofort und künftig bei jeder Anmeldung.

| Aufruf | Wirkung |
|---|---|
| `./conky/install.sh` | installieren, Autostart einrichten, Widget starten |
| `./conky/install.sh --ohne-pakete` | nichts über die Paketverwaltung installieren |
| `./conky/install.sh --entfernen` | Widget beenden und entfernen (Einstellungen bleiben) |

## Einstellen

Im Anwendungsmenü gibt es danach den Eintrag **„Desktop-Widgets“**: einzelne Abschnitte an- und
ausschalten, Ort suchen, Aktualisierungsabstände und Anzahl der Schlagzeilen ändern.

Dasselbe geht von Hand in `~/.config/eierschecke/conky.conf`:

```ini
WIDGETS=an
ORT_NAME=Herzogenaurach
ORT_BREITE=49.57
ORT_LAENGE=10.88
WETTER=an
WETTER_INTERVALL_MIN=30
NACHRICHTEN=an
NACHRICHTEN_INTERVALL_MIN=15
NACHRICHTEN_ANZAHL=7
SYSTEM=an
```

Danach das Widget neu starten:

```bash
~/.local/bin/eierschecke-conky restart
```

Weitere Befehle: `start`, `stop`, `status`.

### Aussehen anpassen

Position, Größe, Farben und Schrift stehen in der Vorlage. Für eigene Änderungen die Vorlage
kopieren – die Kopie hat Vorrang und übersteht Aktualisierungen:

```bash
cp ~/.local/share/eierschecke/conky/conkyrc.vorlage ~/.config/eierschecke/conkyrc.vorlage
```

Nützliche Stellen darin: `alignment` (Ecke), `gap_x`/`gap_y` (Abstand zum Rand),
`own_window_argb_value` (Deckkraft, 0–255), `color1` (Akzentfarbe).

## Was wohin installiert wird

| Datei | Ort |
|---|---|
| `eierschecke-conky`, `-wetter`, `-nachrichten`, `-widgets`, `eierschecke_konfig.py` | `~/.local/bin/` |
| Conky-Vorlage | `~/.local/share/eierschecke/conky/` |
| Menüeintrag „Desktop-Widgets“ | `~/.local/share/applications/` |
| Autostart | `~/.config/autostart/eierschecke-conky.desktop` |
| Einstellungen | `~/.config/eierschecke/conky.conf` |
| Zwischengespeicherte Daten | `~/.cache/eierschecke/` |

## Gut zu wissen

- **Getestet** ist das Widget bisher im EierscheckeOS-ISO; die Skripte für Wetter und
  Schlagzeilen sowie der Ablauf der Installation sind mit Testdaten geprüft. Auf anderen
  Distributionen ist es noch nicht ausprobiert.
- **Wayland:** Conky ist für X11 gemacht. Unter Wayland (z. B. GNOME, KDE Plasma 6) erscheint das
  Fenster je nach Desktop nicht oder nicht an der richtigen Stelle.
- **„Schreibtisch anzeigen“** blendet das Widget auf manchen Desktops mit aus; ein Klick auf ein
  Fenster holt es zurück.
- **Netzzugriffe:** nur `api.open-meteo.com` (Wetter), `geocoding-api.open-meteo.com` (Ortssuche
  im Menü) und `www.tagesschau.de` (Schlagzeilen).
- Das passende dunkle Theme gibt es separat: [theme/README.md](../theme/README.md).
