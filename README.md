# EierscheckeOS

**Schicht für Schicht zum Desktop.** Eine Debian-13-basierte Desktop-Distribution mit Xfce,
optimiert für das Lenovo ThinkPad X280: dunkles Design mit goldgelbem Akzent, vorinstallierte
Alltags- und Bastel-Software, Energiesparen ab Werk und ein Update-Center, das alles in einem
Durchgang aktualisiert.

Aktuelle Version: **1.0 „Quarkkeulchen“** (Entwurf) · [Spezifikation](docs/Spezifikation.md) ·
[Bekannte Einschränkungen](docs/Hinweise.md)

## Herunterladen

Fertige ISOs liegen unter [Releases](../../releases). Ist ein ISO größer als 2 GiB, besteht es
aus mehreren Teilen (`.teil-01`, `.teil-02` …), die nach dem Download zusammengesetzt werden:

```bash
cat eierschecke-os-1.0-amd64.iso.teil-* > eierschecke-os-1.0-amd64.iso
```

```bash
sha256sum -c eierschecke-os-1.0-amd64.iso.sha256
```

Das ISO auf einen USB-Stick schreiben (z. B. mit `dd`, balenaEtcher oder Ventoy), davon starten
und auf dem Desktop **„EierscheckeOS installieren“** wählen.

## Selbst bauen

In GitHub Actions: **Actions → ISO bauen → Run workflow** (Test-Build, ISO als Artefakt). Ein
Tag `v*` erzeugt ein Release; alternativ bei „Run workflow“ ein Release-Tag eintragen. Lokal auf Debian 13 oder MX Linux:

```bash
sudo apt install live-build debootstrap curl gnupg librsvg2-bin xorriso squashfs-tools grub-efi-amd64-bin grub-pc-bin mtools dosfstools
```

```bash
sudo ./build.sh
```

Einzelheiten und Stellschrauben stehen in [docs/Bauen.md](docs/Bauen.md).

## Aufbau des Repos

| Pfad | Inhalt |
|---|---|
| `eierschecke.conf` | Version, Codename, Debian-Basis, gepinnte Fremdversionen |
| `build.sh` | sortiert alles ein und ruft `live-build` auf |
| `.github/workflows/` | `build-iso.yml` (ISO/Release), `pruefen.yml` (statische Prüfungen) |
| `config/package-lists/` | Debian-Pakete (`*.list.chroot`) und optionale Pakete |
| `config/archives/` | Hersteller-Quellen: Mozilla, Brave, Signal, VSCodium, Syncthing, Claude |
| `config/hooks/live/` | Build-Schritte im System: Fremdpakete, Flatpaks, Aussehen, Dienste |
| `config/includes.chroot/` | Dateien fürs System: `/etc/skel` (Xfce-Voreinstellungen), TLP, APT … |
| `config/bootloaders/` | GRUB-Theme des Live-Mediums |
| `branding/` | Logo, Hintergrundbilder, Plymouth-Animation, GRUB-Theme, LightDM |
| `calamares/` | Installer: Ablauf, Btrfs-Schema, Branding, Nachinstallation |
| `conky/` | Desktop-Widget: Wetter (Open-Meteo), Tagesschau, System |
| `tools/` | Update-Center, Widget-Menü, Ersteinrichtung, kleine Helfer |
| `docs/` | Spezifikation, Bau-Anleitung, Hinweise |

## Stand

Das Grundgerüst deckt die Spezifikation ab; getestet ist bisher der Build, noch nicht die echte
Hardware. Offene Punkte (Tests auf dem X280, Abstimmung von Logo und Hintergrundbildern,
Lizenz) stehen in [docs/Hinweise.md](docs/Hinweise.md).
