# Hinweise und bekannte Einschränkungen

## Abweichungen von der Spezifikation

| Punkt | Stand | Grund |
|---|---|---|
| Thunar-Freigabe-Plugin | nicht enthalten | `thunar-shares-plugin` gibt es in Debian 13 nicht. SMB-Freigaben *nutzen* geht über gvfs (`smb://…` in Thunar). |
| Conky Manager 2 | nicht enthalten | nicht in Debian 13; das eigene Menü „Desktop-Widgets“ deckt die Verwaltung ab. |
| Orchis-Dark mit Akzent | wird beim Build aus dem Quelltext gebaut | Das Debian-Paket enthält nur die blaue Variante. Schlägt der Bau fehl, greift Orchis-Dark bzw. Arc-Dark. |
| grub-btrfs | wird beim Build von GitHub geladen (gepinnte Version) | nicht in Debian 13. |
| Brother `brscan3`/`brscan-skey` | werden beim ersten Start mit Netz von Brother geladen | proprietär, keine Weiterverteilung im ISO. Adressen: `/etc/eierschecke/brother.conf`. |
| Startmenü-Eintrag heißt „Debian GNU/Linux“ | bewusst | Debians signiertes GRUB (Secure Boot) erwartet seine Konfiguration unter `EFI/debian`. Ein anderer Name würde Secure Boot brechen. |
| BIOS-Start | zusätzlich möglich | Das ISO startet per UEFI (mit Secure Boot) und zusätzlich per BIOS – praktisch für Tests in VMs. |

## Bekannte Einschränkungen

- **Ruhezustand und Secure Boot:** Bei aktivem Secure Boot sperrt der Kernel den Ruhezustand
  (Kernel-Lockdown). Hibernate funktioniert also nur mit abgeschaltetem Secure Boot; Standby
  ist nicht betroffen.
- **Snapshot aus dem GRUB-Menü starten:** Ein gestarteter Snapshot ist schreibgeschützt und
  dient zum Nachsehen und Retten. Ein dauerhaftes Zurückrollen von `/` ist noch nicht per
  Knopfdruck gelöst; einzelne Änderungen lassen sich mit `snapper undochange` oder
  `snapper-gui` zurücknehmen.
- **Swap-Datei:** Sie wird bei der Installation in Größe des Arbeitsspeichers angelegt, wenn
  danach noch mindestens 15 GiB frei bleiben. Bei manueller Partitionierung ohne eigenes
  `/swap`-Subvolume entfällt sie.
- **Claude Desktop** ist unter Linux Beta: kein Computer Use, kein Diktat. Die Anmeldung
  braucht einen Schlüsselbund (GNOME Keyring ist installiert).
- **Flatpak-Anwendungen** übernehmen das GTK-Theme nur teilweise; sie folgen aber dem dunklen
  Farbschema.
- **Wetter-Symbole** im Conky-Widget stammen aus DejaVu Sans (einfarbig).
- **Hintergrundbild** ist für `eDP-1` (ThinkPad) und virtuelle Maschinen voreingestellt;
  auf anderen Bildschirmen setzt es Variety nach dem ersten Wechsel.

## Offene Punkte

- [ ] Erstes Test-ISO in einer VM prüfen, danach auf dem X280
- [ ] Funktionstasten auf echter Hardware testen (v. a. Mikrofon-LED, Fn-Lock, F9–F12)
- [ ] Logo, Hintergrundbilder und Plymouth-Animation abstimmen (bisher erster Entwurf)
- [ ] Download-Adressen der Brother-Treiber auf echter Hardware bestätigen
- [ ] Lizenz für die eigenen Skripte und Grafiken festlegen (z. B. GPL-3.0-or-later / CC BY-SA)
- [ ] Fingerabdrücke der übrigen Hersteller-Schlüssel in `config/archives/schluessel.conf` eintragen
- [ ] Eigenes APT-Repo auf GitHub Pages für Distro-Pakete (Spezifikation §9)
- [ ] `docker-compose.yml` für FreshRSS und oPodSync (Spezifikation §11)
