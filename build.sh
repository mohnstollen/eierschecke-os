#!/bin/bash
# Baut das EierscheckeOS-Live-ISO mit Debians live-build.
#
#   sudo ./build.sh
#
# Umgebungsvariablen:
#   EIERSCHECKE_FLATPAKS=iso|erststart   Flatpaks ins ISO einbauen (Standard) oder
#                                        erst beim ersten Start mit Netz nachladen
#   EIERSCHECKE_KOMPRESSION=zstd|xz      SquashFS-Kompression (zstd: schnell, xz: klein)
#   EIERSCHECKE_SPIEGEL=URL              Debian-Spiegel (Standard: deb.debian.org)
set -euo pipefail

WURZEL="$(dirname "$(readlink -f "$0")")"
cd "$WURZEL"
# shellcheck source=eierschecke.conf
. ./eierschecke.conf

FLATPAKS="${EIERSCHECKE_FLATPAKS:-iso}"
KOMPRESSION="${EIERSCHECKE_KOMPRESSION:-zstd}"
SPIEGEL="${EIERSCHECKE_SPIEGEL:-http://deb.debian.org/debian/}"
BUILD="$WURZEL/build"
AUSGABE="$WURZEL/ausgabe"
INC="$BUILD/config/includes.chroot_after_packages"
ISO_NAME="eierschecke-os-${EIERSCHECKE_VERSION}-amd64"

info()   { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
fehler() { printf '\033[1;31mFehler:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fehler "Bitte mit sudo starten: sudo ./build.sh"
case "$FLATPAKS" in iso|erststart) ;; *) fehler "EIERSCHECKE_FLATPAKS muss 'iso' oder 'erststart' sein" ;; esac
case "$KOMPRESSION" in zstd|xz) ;; *) fehler "EIERSCHECKE_KOMPRESSION muss 'zstd' oder 'xz' sein" ;; esac

fehlend=""
for werkzeug in lb debootstrap curl gpg rsvg-convert xorriso mksquashfs; do
    command -v "$werkzeug" >/dev/null || fehlend="$fehlend $werkzeug"
done
[ -z "$fehlend" ] || fehler "Es fehlen Werkzeuge:$fehlend
Installieren mit:
  apt install live-build debootstrap curl gnupg librsvg2-bin xorriso squashfs-tools \\
              grub-efi-amd64-bin grub-pc-bin mtools dosfstools ca-certificates"

# ---------------------------------------------------------------------------
info "Build-Verzeichnis vorbereiten"
if [ -d "$BUILD/.build" ]; then
    (cd "$BUILD" && lb clean --purge) || true
fi
rm -rf "$BUILD/config" "$BUILD/auto"
mkdir -p "$BUILD/config" "$INC" "$AUSGABE"
cp -a config/package-lists config/hooks "$BUILD/config/"
# Nur *.list.chroot sind echte live-build-Paketlisten
find "$BUILD/config/package-lists" -type f ! -name '*.list.chroot' -delete
cp -a config/includes.chroot/. "$INC/"

# ---------------------------------------------------------------------------
info "Eigene Komponenten einsortieren"
SHARE="$INC/usr/share/eierschecke"
mkdir -p "$SHARE"

# Eckdaten für Hooks und das laufende System
install -Dm644 eierschecke.conf "$SHARE/eierschecke.conf"
printf 'FLATPAKS="%s"\n' "$FLATPAKS" > "$SHARE/build.conf"
install -Dm644 config/package-lists/optional.pakete "$SHARE/optional.pakete"

# Branding (wird im Hook 0300 gerendert und verteilt)
mkdir -p "$SHARE/branding"
cp -a branding/. "$SHARE/branding/"

# Calamares
mkdir -p "$INC/etc/calamares"
cp -a calamares/settings.conf calamares/modules calamares/branding "$INC/etc/calamares/"
install -Dm755 calamares/eierschecke-installer        "$INC/usr/bin/eierschecke-installer"
install -Dm755 calamares/eierschecke-nachinstallation "$INC/usr/libexec/eierschecke/nachinstallation"
install -Dm755 calamares/eierschecke-live-sitzung     "$INC/usr/libexec/eierschecke/live-sitzung"
install -Dm644 calamares/eierschecke-installer.desktop "$INC/usr/share/applications/eierschecke-installer.desktop"
install -Dm644 calamares/eierschecke-live.desktop      "$INC/etc/xdg/autostart/eierschecke-live.desktop"

# Conky
install -Dm755 conky/eierschecke-conky        "$INC/usr/bin/eierschecke-conky"
install -Dm755 conky/eierschecke-wetter       "$INC/usr/bin/eierschecke-wetter"
install -Dm755 conky/eierschecke-nachrichten  "$INC/usr/bin/eierschecke-nachrichten"
install -Dm644 conky/eierschecke_konfig.py    "$INC/usr/lib/python3/dist-packages/eierschecke_konfig.py"
install -Dm644 conky/conkyrc.vorlage          "$SHARE/conky/conkyrc.vorlage"
install -Dm644 conky/eierschecke-conky.desktop "$INC/etc/xdg/autostart/eierschecke-conky.desktop"

# Werkzeuge
install -Dm755 tools/widget-menue/eierschecke-widgets          "$INC/usr/bin/eierschecke-widgets"
install -Dm644 tools/widget-menue/eierschecke-widgets.desktop  "$INC/usr/share/applications/eierschecke-widgets.desktop"
install -Dm755 tools/update-center/eierschecke-update          "$INC/usr/bin/eierschecke-update"
install -Dm755 tools/update-center/eierschecke-update-tray     "$INC/usr/bin/eierschecke-update-tray"
install -Dm755 tools/update-center/eierschecke-update-backend  "$INC/usr/libexec/eierschecke/update-backend"
install -Dm644 tools/update-center/eierschecke_updates.py     "$INC/usr/lib/python3/dist-packages/eierschecke_updates.py"
install -Dm644 tools/update-center/eierschecke-update.desktop  "$INC/usr/share/applications/eierschecke-update.desktop"
install -Dm644 tools/update-center/eierschecke-update-tray.desktop "$INC/etc/xdg/autostart/eierschecke-update-tray.desktop"
install -Dm644 tools/update-center/org.eierschecke.update.policy   "$INC/usr/share/polkit-1/actions/org.eierschecke.update.policy"
for einheit in tools/system/*.service tools/system/*.timer; do
    install -Dm644 "$einheit" "$INC/etc/systemd/system/$(basename "$einheit")"
done
for skript in ersteinrichtung flatpak-setup brother-setup papirus-ordner; do
    install -Dm755 "tools/system/eierschecke-$skript" "$INC/usr/libexec/eierschecke/$skript"
done
install -Dm755 tools/system/eierschecke-pdf-ocr  "$INC/usr/bin/eierschecke-pdf-ocr"
install -Dm755 tools/system/eierschecke-akku     "$INC/usr/bin/eierschecke-akku"
install -Dm644 tools/system/eierschecke-akku.desktop "$INC/usr/share/applications/eierschecke-akku.desktop"
install -Dm644 tools/system/flatpaks.list  "$SHARE/flatpaks.list"
install -Dm644 tools/system/brother.conf   "$INC/etc/eierschecke/brother.conf"

# ---------------------------------------------------------------------------
info "Fremdquellen: Schlüssel laden und prüfen"
install -Dm644 config/archives/fremdpakete.pakete "$SHARE/fremdpakete.pakete"
mkdir -p "$INC/etc/apt/sources.list.d" "$INC/etc/apt/preferences.d"
for datei in config/archives/*.sources config/archives/*.list; do
    install -m644 "$datei" "$INC/etc/apt/sources.list.d/"
done
for datei in config/archives/*.pref; do
    install -m644 "$datei" "$INC/etc/apt/preferences.d/$(basename "$datei" .pref)"
done
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
while read -r name url ziel format abdruck; do
    case "$name" in ''|\#*) continue ;; esac
    roh="$TMP/$name.key"
    curl -fsSL --retry 3 -o "$roh" "$url" || fehler "Schlüssel für $name nicht ladbar: $url"
    gefunden="$(gpg --show-keys --with-colons "$roh" 2>/dev/null | awk -F: '$1=="fpr"{print $10}' || true)"
    [ -n "$gefunden" ] || fehler "Schlüssel für $name ist kein gültiger OpenPGP-Schlüssel"
    if [ "${abdruck:--}" != "-" ] && ! grep -qx "$abdruck" <<<"$gefunden"; then
        fehler "Schlüssel für $name hat nicht den erwarteten Fingerabdruck $abdruck"
    fi
    echo "    $name: $(head -n1 <<<"$gefunden")"
    mkdir -p "$(dirname "$INC$ziel")"
    if [ "$format" = "binaer" ] && grep -q 'BEGIN PGP' "$roh"; then
        gpg --dearmor < "$roh" > "$INC$ziel"
    else
        cp "$roh" "$INC$ziel"
    fi
    chmod 644 "$INC$ziel"
done < config/archives/schluessel.conf

# Alles, was ins System wandert, gehört root – unabhängig davon, wem das Repo gehört.
chown -R 0:0 "$BUILD/config"

# ---------------------------------------------------------------------------
info "Bootmenü des Live-Mediums gestalten"
VORLAGEN=/usr/share/live/build/bootloaders
if [ -d "$VORLAGEN/grub-pc" ]; then
    mkdir -p "$BUILD/config/bootloaders"
    cp -a "$VORLAGEN/grub-pc" "$BUILD/config/bootloaders/"
    LB_THEMA="$BUILD/config/bootloaders/grub-pc"
    cp -a config/bootloaders/grub-pc/. "$LB_THEMA/"
    rsvg-convert -w 1920 -h 1080 branding/grub/hintergrund.svg -o "$LB_THEMA/splash.png"
    rsvg-convert -w 160 -h 160 branding/logo/eierschecke.svg -o "$LB_THEMA/live-theme/logo.png"
else
    echo "    Keine live-build-Vorlagen gefunden – Standard-Bootmenü wird verwendet."
fi

# ---------------------------------------------------------------------------
info "live-build konfigurieren"
cd "$BUILD"
lb config \
    --mode debian \
    --distribution "$DEBIAN_SUITE" \
    --archive-areas "main contrib non-free non-free-firmware" \
    --architectures amd64 \
    --linux-flavours amd64 \
    --binary-images iso-hybrid \
    --bootloaders "grub-pc,grub-efi" \
    --uefi-secure-boot enable \
    --debian-installer none \
    --memtest none \
    --apt-recommends true \
    --firmware-chroot false \
    --firmware-binary false \
    --security true \
    --updates true \
    --backports false \
    --cache false \
    --mirror-bootstrap "$SPIEGEL" \
    --mirror-chroot "$SPIEGEL" \
    --mirror-binary "http://deb.debian.org/debian/" \
    --chroot-squashfs-compression-type "$KOMPRESSION" \
    --image-name "$ISO_NAME" \
    --iso-application "EierscheckeOS" \
    --iso-publisher "EierscheckeOS; $PROJEKT_URL" \
    --iso-volume "EierscheckeOS $EIERSCHECKE_VERSION" \
    --bootappend-live "boot=live components quiet splash locales=de_DE.UTF-8 keyboard-layouts=de keyboard-variants=nodeadkeys timezone=Europe/Berlin hostname=eierschecke username=gast user-fullname=EierscheckeOS-Gast"

info "ISO bauen (das dauert …)"
lb build 2>&1 | tee "$BUILD/build.log"

ISO="$(find "$BUILD" -maxdepth 1 -name "${ISO_NAME}*.iso" | head -n1)"
[ -n "$ISO" ] || fehler "Kein ISO entstanden – siehe $BUILD/build.log"
mv "$ISO" "$AUSGABE/$ISO_NAME.iso"
(cd "$AUSGABE" && sha256sum "$ISO_NAME.iso" > "$ISO_NAME.iso.sha256")

# Hinweise aus den Hooks (nicht installierbare optionale Pakete usw.)
WARNUNGEN="$BUILD/chroot/var/log/eierschecke-build-warnungen.log"
if [ -s "$WARNUNGEN" ]; then
    cp "$WARNUNGEN" "$AUSGABE/build-warnungen.log"
    info "Hinweise aus dem Build:"
    sed 's/^/    /' "$WARNUNGEN"
else
    : > "$AUSGABE/build-warnungen.log"
fi

info "Fertig: $AUSGABE/$ISO_NAME.iso ($(du -h "$AUSGABE/$ISO_NAME.iso" | cut -f1))"
