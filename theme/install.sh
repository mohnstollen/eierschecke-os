#!/bin/bash
# Installiert das EierscheckeOS-Aussehen auf einem beliebigen Xfce-Desktop.
#
#   ./theme/install.sh              Theme, Icons, Schriften, Hintergrundbilder, Terminalfarben
#   ./theme/install.sh --panel      zusätzlich die Panel-Anordnung (unten, Whisker-Menü)
#   ./theme/install.sh --system     zusätzlich Boot-Animation, GRUB-Theme und Anmeldebildschirm
#                                   (nur Debian/Ubuntu/Mint/MX, braucht sudo)
#   ./theme/install.sh --entfernen  vorherige Einstellungen wiederherstellen
#
# Weitere Schalter: --ohne-pakete (nichts über die Paketverwaltung installieren)
#
# Ohne --system läuft alles im eigenen Benutzerkonto; sudo wird nur für fehlende
# Pakete und die gelben Papirus-Ordner gebraucht.
set -euo pipefail

REPO="$(dirname "$(dirname "$(readlink -f "$0")")")"
# shellcheck source=../eierschecke.conf
. "$REPO/eierschecke.conf"
B="$REPO/branding"
SKEL="$REPO/config/includes.chroot/etc/skel/.config"
ZUSTAND="$HOME/.config/eierschecke"
SICHERUNG="$ZUSTAND/theme-sicherung.conf"
THEMEN="$HOME/.themes"
BILDER="$HOME/.local/share/backgrounds/eierschecke"
ICONS="$HOME/.local/share/icons/hicolor"
PANEL_XML="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

PANEL=0; SYSTEM=0; ENTFERNEN=0; PAKETE=1
for schalter in "$@"; do
    case "$schalter" in
        --panel) PANEL=1 ;;
        --system) SYSTEM=1 ;;
        --entfernen) ENTFERNEN=1 ;;
        --ohne-pakete) PAKETE=0 ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unbekannter Schalter: $schalter (Hilfe: --help)" >&2; exit 2 ;;
    esac
done

info()    { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
hinweis() { printf '\033[1;31m  !\033[0m %s\n' "$*" >&2; }
hat()     { command -v "$1" >/dev/null 2>&1; }

[ "$(id -u)" -ne 0 ] || { echo "Bitte als normaler Benutzer starten, nicht als root." >&2; exit 1; }
hat xfconf-query || { echo "xfconf-query fehlt – läuft hier Xfce?" >&2; exit 1; }
mkdir -p "$ZUSTAND"

# --- Xfce-Einstellungen setzen und den alten Wert einmalig sichern ----------------
setze() {  # setze <Kanal> <Eigenschaft> <Typ> <Wert>
    local kanal="$1" eigenschaft="$2" typ="$3" wert="$4" alt
    if ! grep -qsF "$kanal|$eigenschaft|" "$SICHERUNG"; then
        if alt="$(xfconf-query -c "$kanal" -p "$eigenschaft" 2>/dev/null)"; then
            printf '%s|%s|%s|%s\n' "$kanal" "$eigenschaft" "$typ" "$alt" >> "$SICHERUNG"
        else
            printf '%s|%s|%s|%s\n' "$kanal" "$eigenschaft" "-" "" >> "$SICHERUNG"
        fi
    fi
    xfconf-query -c "$kanal" -p "$eigenschaft" -n -t "$typ" -s "$wert"
}

panel_neu_starten() {
    pkill -u "$(id -u)" -x xfconfd 2>/dev/null || true
    (xfce4-panel >/dev/null 2>&1 &)
}

# --- Entfernen ----------------------------------------------------------------------------
if [ "$ENTFERNEN" = 1 ]; then
    info "Vorherige Xfce-Einstellungen wiederherstellen"
    if [ -f "$SICHERUNG" ]; then
        while IFS='|' read -r kanal eigenschaft typ wert; do
            if [ "$typ" = "-" ]; then
                xfconf-query -c "$kanal" -p "$eigenschaft" -r 2>/dev/null || true
            else
                xfconf-query -c "$kanal" -p "$eigenschaft" -n -t "$typ" -s "$wert" || true
            fi
        done < "$SICHERUNG"
        rm -f "$SICHERUNG"
    else
        hinweis "Keine Sicherung gefunden – Einstellungen bleiben, wie sie sind."
    fi
    if [ -f "$ZUSTAND/xfce4-panel.xml.vorher" ]; then
        info "Vorheriges Panel wiederherstellen"
        xfce4-panel --quit 2>/dev/null || true
        cp "$ZUSTAND/xfce4-panel.xml.vorher" "$PANEL_XML"
        panel_neu_starten
        rm -f "$ZUSTAND/xfce4-panel.xml.vorher"
    fi
    # Nur die eigenen, fest benannten Dateien löschen
    for variante in "" -hdpi -xhdpi -Compact -Compact-hdpi -Compact-xhdpi; do
        rm -rf "$HOME/.themes/Eierschecke-Yellow-Dark$variante"
    done
    rm -rf "$HOME/.local/share/backgrounds/eierschecke"
    rm -f "$HOME/.themes/Eierschecke-Dark" "$HOME/.local/share/icons/hicolor/scalable/apps/eierschecke-logo.svg"
    if hat gsettings; then
        gsettings reset org.gnome.desktop.interface color-scheme 2>/dev/null || true
    fi
    echo "Fertig. Boot-Animation, GRUB-Theme und Anmeldebildschirm (--system) bleiben bestehen;"
    echo "wie man sie zurückstellt, steht in theme/README.md."
    exit 0
fi

# --- 1. Pakete ------------------------------------------------------------------------------
if [ "$PAKETE" = 1 ]; then
    info "Benötigte Pakete installieren (sudo)"
    if hat apt-get; then
        sudo apt-get update || true
        for paket in git sassc librsvg2-bin papirus-icon-theme fonts-inter fonts-jetbrains-mono; do
            dpkg -s "$paket" >/dev/null 2>&1 || sudo apt-get install -y "$paket" \
                || hinweis "Paket $paket nicht installierbar – bitte von Hand nachholen"
        done
    elif hat dnf; then
        sudo dnf install -y git sassc librsvg2-tools papirus-icon-theme rsms-inter-fonts jetbrains-mono-fonts \
            || hinweis "Nicht alle Pakete installierbar"
    elif hat pacman; then
        sudo pacman -S --needed --noconfirm git sassc librsvg papirus-icon-theme inter-font ttf-jetbrains-mono \
            || hinweis "Nicht alle Pakete installierbar"
    elif hat zypper; then
        sudo zypper --non-interactive install git sassc rsvg-convert papirus-icon-theme \
            || hinweis "Nicht alle Pakete installierbar"
        hinweis "Die Schriften Inter und JetBrains Mono bitte von Hand installieren."
    else
        hinweis "Unbekannte Paketverwaltung – gebraucht werden: git, sassc, rsvg-convert,"
        hinweis "Papirus-Icons sowie die Schriften Inter und JetBrains Mono."
    fi
fi
for werkzeug in git sassc rsvg-convert; do
    hat "$werkzeug" || { echo "Es fehlt: $werkzeug" >&2; exit 1; }
done

# --- 2. GTK- und Fenster-Theme: Orchis-Dark mit Eiercreme-Akzent -------------------
info "GTK-Theme bauen (Orchis-Dark mit Akzent $AKZENTFARBE)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ORCHIS_VERSION" \
    https://github.com/vinceliuice/Orchis-theme "$TMP/orchis"
sed -i "s/^\(\$yellow-dark:\).*/\1 $AKZENTFARBE;/; s/^\(\$yellow-light:\).*/\1 $AKZENTFARBE;/" \
    "$TMP/orchis/src/_sass/_color-palette-default.scss"
mkdir -p "$THEMEN"
(cd "$TMP/orchis" && ./install.sh --dest "$THEMEN" --name Eierschecke --theme yellow --color dark --size standard) >/dev/null
[ -d "$THEMEN/Eierschecke-Yellow-Dark/gtk-3.0" ] || { echo "Theme-Bau fehlgeschlagen." >&2; exit 1; }
ln -sfn Eierschecke-Yellow-Dark "$THEMEN/Eierschecke-Dark"

# --- 3. Logo und Hintergrundbilder ---------------------------------------------------
info "Logo und Hintergrundbilder rendern"
install -Dm644 "$B/logo/eierschecke.svg" "$ICONS/scalable/apps/eierschecke-logo.svg"
mkdir -p "$BILDER"
for svg in "$B"/wallpaper/*.svg; do
    rsvg-convert -w 1920 -h 1080 "$svg" -o "$BILDER/$(basename "$svg" .svg).png"
done

# --- 4. Gelbe Ordner (Papirus liegt systemweit → sudo) ---------------------------
if [ -d /usr/share/icons/Papirus ]; then
    info "Papirus-Ordner auf Gelb stellen (sudo)"
    sudo sh "$REPO/tools/system/eierschecke-papirus-ordner" \
        || hinweis "Ordnerfarbe nicht geändert – die Icons bleiben blau"
else
    hinweis "Papirus-Icons nicht gefunden – es bleibt beim bisherigen Icon-Theme."
fi

# --- 5. Xfce-Einstellungen ---------------------------------------------------------------
info "Xfce einstellen"
setze xsettings /Net/ThemeName string "Eierschecke-Dark"
if [ -d /usr/share/icons/Papirus-Dark ]; then
    setze xsettings /Net/IconThemeName string "Papirus-Dark"
fi
if fc-list : family 2>/dev/null | grep -qiw 'Inter'; then
    setze xsettings /Gtk/FontName string "Inter 10"
    setze xfwm4 /general/title_font string "Inter Semi-Bold 10"
else
    hinweis "Schrift Inter fehlt – die bisherige Schrift bleibt."
fi
MONO=0
if fc-list : family 2>/dev/null | grep -qi 'JetBrains Mono'; then
    MONO=1
    setze xsettings /Gtk/MonospaceFontName string "JetBrains Mono 10"
fi
setze xfwm4 /general/theme string "Eierschecke-Dark"

# Terminal (xfce4-terminal ab 1.1 speichert in xfconf)
if hat xfce4-terminal; then
    setze xfce4-terminal /color-use-theme bool false
    setze xfce4-terminal /color-foreground string "#e6e1d6"
    setze xfce4-terminal /color-background string "#1e1e22"
    setze xfce4-terminal /color-cursor string "#e8b84a"
    setze xfce4-terminal /color-cursor-use-default bool false
    setze xfce4-terminal /color-palette string \
        "#2a2a30;#e06c60;#9bbf6a;#e8b84a;#6c9fd8;#b48ead;#6fb8b0;#d8d4c8;#55555e;#f08a7e;#b5d688;#f6d27a;#8bb8ea;#c9a6c4;#8fd0c8;#f6ecd2"
    if [ "$MONO" = 1 ]; then
        setze xfce4-terminal /font-use-system bool false
        setze xfce4-terminal /font-name string "JetBrains Mono 11"
    fi
fi

# Hintergrundbild auf allen bekannten Bildschirmen
while read -r eigenschaft; do
    setze xfce4-desktop "$eigenschaft" string "$BILDER/schichten.png"
done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$' || true)

# Dunkles Farbschema für GTK4-/Flatpak-Anwendungen
if hat gsettings; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
fi

# --- 6. Panel (optional) -------------------------------------------------------------------
if [ "$PANEL" = 1 ]; then
    info "Panel-Anordnung übernehmen"
    if [ ! -f "$ZUSTAND/xfce4-panel.xml.vorher" ] && [ -f "$PANEL_XML" ]; then
        cp "$PANEL_XML" "$ZUSTAND/xfce4-panel.xml.vorher"
    fi
    xfce4-panel --quit 2>/dev/null || true
    mkdir -p "$(dirname "$PANEL_XML")"
    cp "$SKEL/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$PANEL_XML"
    panel_neu_starten
    hinweis "Das Panel braucht das Whisker-Menü (xfce4-whiskermenu-plugin) und das PulseAudio-Plugin."
fi

# --- 7. Boot-Animation, GRUB, Anmeldung (optional, systemweit) --------------------
if [ "$SYSTEM" = 1 ]; then
    if ! hat apt-get; then
        hinweis "--system ist nur für Debian, Ubuntu, Mint und MX vorgesehen – übersprungen."
    else
        info "Boot-Animation (Plymouth) einrichten (sudo)"
        if [ "$PAKETE" = 1 ]; then
            sudo apt-get install -y plymouth plymouth-themes || true
        fi
        P=/usr/share/plymouth/themes/eierschecke
        sudo mkdir -p "$P"
        sudo cp "$B/plymouth/eierschecke.plymouth" "$B/plymouth/eierschecke.script" "$P/"
        for schicht in boden quark creme kruste; do
            rsvg-convert -w 320 -h 320 "$B/plymouth/$schicht.svg" -o "$TMP/$schicht.png"
            sudo install -m644 "$TMP/$schicht.png" "$P/$schicht.png"
        done
        sudo plymouth-set-default-theme -R eierschecke || hinweis "Plymouth-Theme nicht gesetzt"

        if [ -d /etc/default/grub.d ] && hat update-grub; then
            info "GRUB-Theme einrichten (sudo)"
            G=/usr/share/grub/themes/eierschecke
            sudo mkdir -p "$G"
            rsvg-convert -w 1920 -h 1080 "$B/grub/hintergrund.svg" -o "$TMP/hintergrund.png"
            rsvg-convert -w 160 -h 160 "$B/logo/eierschecke.svg" -o "$TMP/logo.png"
            sudo install -m644 "$B/grub/theme.txt" "$TMP/hintergrund.png" "$TMP/logo.png" "$G/"
            schrift="$(fc-match -f '%{file}' 'Inter:style=Regular' 2>/dev/null || true)"
            [ -f "$schrift" ] || schrift=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
            for groesse in 14 18; do
                sudo grub-mkfont -n Eierschecke -s "$groesse" -o "$G/eierschecke-$groesse.pf2" "$schrift" || true
            done
            printf 'GRUB_THEME=%s/theme.txt\nGRUB_GFXMODE=auto\n' "$G" \
                | sudo tee /etc/default/grub.d/eierschecke-theme.cfg >/dev/null
            sudo update-grub
        else
            hinweis "GRUB-Theme übersprungen (kein /etc/default/grub.d oder update-grub)."
        fi

        if [ -d /etc/lightdm ] && dpkg -s lightdm-gtk-greeter >/dev/null 2>&1; then
            info "Anmeldebildschirm (LightDM) einrichten (sudo)"
            sudo mkdir -p /usr/share/eierschecke /usr/share/icons/hicolor/128x128/apps
            sudo cp -r "$THEMEN/Eierschecke-Yellow-Dark" /usr/share/themes/
            sudo ln -sfn Eierschecke-Yellow-Dark /usr/share/themes/Eierschecke-Dark
            sudo install -m644 "$BILDER/schichten.png" /usr/share/eierschecke/anmeldung.png
            rsvg-convert -w 128 -h 128 "$B/logo/eierschecke.svg" -o "$TMP/logo128.png"
            sudo install -m644 "$TMP/logo128.png" /usr/share/icons/hicolor/128x128/apps/eierschecke-logo.png
            if [ -f /etc/lightdm/lightdm-gtk-greeter.conf ] && [ ! -f /etc/lightdm/lightdm-gtk-greeter.conf.vorher ]; then
                sudo cp /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.vorher
            fi
            sudo install -m644 "$B/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
        else
            hinweis "Anmeldebildschirm übersprungen (kein LightDM mit GTK-Greeter)."
        fi
    fi
fi

info "Fertig. Falls einzelne Programme noch hell sind: einmal ab- und wieder anmelden."
echo "    Rückgängig machen: $0 --entfernen"
