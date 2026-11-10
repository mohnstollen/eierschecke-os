# ISO bauen

## So läuft der Build ab

`build.sh` baut nicht direkt im Repo, sondern legt ein Arbeitsverzeichnis `build/` an:

1. `config/` wird nach `build/config/` kopiert.
2. Die Komponenten aus `branding/`, `calamares/`, `conky/` und `tools/` werden an ihre Plätze
   im System einsortiert (`build/config/includes.chroot_after_packages/`).
3. Die Signaturschlüssel der Hersteller-Quellen werden geladen und – wo ein Fingerabdruck
   hinterlegt ist – geprüft (`config/archives/schluessel.conf`).
4. Das GRUB-Menü des Live-Mediums wird aus der live-build-Vorlage plus unserem Theme gebaut.
5. `lb config` und `lb build` erzeugen das ISO; es landet mit Prüfsumme in `ausgabe/`.

Im entstehenden System laufen dann die Hooks aus `config/hooks/live/`:

| Hook | Aufgabe |
|---|---|
| `0100-fremdquellen` | Firefox, Brave, Signal, VSCodium, Syncthing, Claude Desktop installieren |
| `0110-optionale-pakete` | Pakete aus `optional.pakete` einzeln installieren |
| `0200-flatpak` | Flathub einrichten, Flatpaks vorinstallieren |
| `0300-aussehen` | Orchis mit Akzentfarbe bauen, gelbe Ordner, Bilder rendern, Plymouth, GRUB, LightDM |
| `0320-grub-btrfs` | grub-btrfs von GitHub (nicht in Debian enthalten) |
| `0400-system` | Sprache, `os-release`, Dienste, Initramfs |

Bilder liegen im Repo nur als SVG; PNGs entstehen beim Build mit `rsvg-convert`.

## Stellschrauben

| Variable | Werte | Wirkung |
|---|---|---|
| `EIERSCHECKE_FLATPAKS` | `iso` (Standard), `erststart` | Flatpaks ins ISO einbauen oder erst beim ersten Start mit Netz laden (kleineres ISO) |
| `EIERSCHECKE_KOMPRESSION` | `zstd` (Standard lokal), `xz` | `zstd` baut schnell, `xz` ergibt ein kleineres ISO (Standard für Releases) |
| `EIERSCHECKE_SPIEGEL` | URL | Debian-Spiegel für den Build |

```bash
sudo EIERSCHECKE_FLATPAKS=erststart ./build.sh
```

Ein Build braucht Root-Rechte, rund 30 GB freien Platz und je nach Leitung 30–90 Minuten.

## Robuster Build

Damit ein einzelnes fehlendes Paket nicht den ganzen Build kippt, gibt es zwei Stufen:

- `config/package-lists/*.list.chroot` – Pflichtpakete; fehlt eines, bricht der Build ab.
- `config/package-lists/optional.pakete`, `config/archives/fremdpakete.pakete` und die
  Flatpaks – werden einzeln installiert. Was nicht klappt, steht am Ende in
  `ausgabe/build-warnungen.log` (in GitHub Actions auch in der Zusammenfassung des Laufs).

Fehlende Flatpaks holt das installierte System beim ersten Start mit Netz selbst nach.

## Neue Version

1. `eierschecke.conf` anpassen (Version, Codename – das nächste sächsische Gebäck).
2. Versionsangaben in `calamares/branding/eierschecke/branding.desc` nachziehen.
3. Tag setzen und pushen, z. B. `v1.1` – GitHub Actions baut das ISO und legt das Release an.
