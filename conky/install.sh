#!/bin/bash
# Installiert das EierscheckeOS-Desktop-Widget (Conky mit Wetter, Tagesschau und
# Systemdaten) im eigenen Benutzerkonto – auf jedem Linux-Desktop mit X11.
#
#   ./conky/install.sh              installieren, Autostart einrichten, Widget starten
#   ./conky/install.sh --entfernen  Widget beenden und wieder entfernen
#
# Weitere Schalter: --ohne-pakete (nichts über die Paketverwaltung installieren)
#
# sudo wird nur gebraucht, um fehlende Pakete zu installieren (Conky, Python-GTK).
set -euo pipefail

REPO="$(dirname "$(dirname "$(readlink -f "$0")")")"
BIN="$HOME/.local/bin"
DATEN="$HOME/.local/share/eierschecke/conky"
STARTER="$HOME/.local/share/applications/eierschecke-widgets.desktop"
AUTOSTART="$HOME/.config/autostart/eierschecke-conky.desktop"
SKRIPTE="eierschecke-conky eierschecke-wetter eierschecke-nachrichten eierschecke-widgets"

ENTFERNEN=0; PAKETE=1
for schalter in "$@"; do
    case "$schalter" in
        --entfernen) ENTFERNEN=1 ;;
        --ohne-pakete) PAKETE=0 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unbekannter Schalter: $schalter (Hilfe: --help)" >&2; exit 2 ;;
    esac
done

info()    { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
hinweis() { printf '\033[1;31m  !\033[0m %s\n' "$*" >&2; }
hat()     { command -v "$1" >/dev/null 2>&1; }

[ "$(id -u)" -ne 0 ] || { echo "Bitte als normaler Benutzer starten, nicht als root." >&2; exit 1; }

# --- Entfernen ----------------------------------------------------------------------------
if [ "$ENTFERNEN" = 1 ]; then
    info "Widget beenden und entfernen"
    if [ -x "$BIN/eierschecke-conky" ]; then
        "$BIN/eierschecke-conky" stop || true
    fi
    for skript in $SKRIPTE; do
        rm -f "$HOME/.local/bin/$skript"
    done
    rm -f "$HOME/.local/bin/eierschecke_konfig.py" \
          "$HOME/.local/share/eierschecke/conky/conkyrc.vorlage" \
          "$HOME/.local/share/applications/eierschecke-widgets.desktop" \
          "$HOME/.config/autostart/eierschecke-conky.desktop" \
          "$HOME/.cache/eierschecke/conkyrc" \
          "$HOME/.cache/eierschecke/wetter.json" \
          "$HOME/.cache/eierschecke/nachrichten.json"
    find "$HOME/.local/bin/__pycache__" -name 'eierschecke_konfig.*.pyc' -delete 2>/dev/null || true
    rmdir "$HOME/.local/share/eierschecke/conky" "$HOME/.local/share/eierschecke" 2>/dev/null || true
    echo "Fertig. Die Einstellungen in ~/.config/eierschecke/conky.conf bleiben erhalten."
    exit 0
fi

# --- 1. Pakete ------------------------------------------------------------------------------
if [ "$PAKETE" = 1 ]; then
    info "Benötigte Pakete installieren (sudo)"
    if hat apt-get; then
        sudo apt-get update || true
        hat conky || sudo apt-get install -y conky-all || sudo apt-get install -y conky-std \
            || hinweis "Conky nicht installierbar – bitte von Hand nachholen"
        for paket in python3 python3-gi gir1.2-gtk-3.0 fonts-dejavu-core fonts-inter; do
            dpkg -s "$paket" >/dev/null 2>&1 || sudo apt-get install -y "$paket" \
                || hinweis "Paket $paket nicht installierbar"
        done
    elif hat dnf; then
        sudo dnf install -y conky python3 python3-gobject gtk3 dejavu-sans-fonts rsms-inter-fonts \
            || hinweis "Nicht alle Pakete installierbar"
    elif hat pacman; then
        sudo pacman -S --needed --noconfirm conky python python-gobject gtk3 ttf-dejavu inter-font \
            || hinweis "Nicht alle Pakete installierbar"
    elif hat zypper; then
        sudo zypper --non-interactive install conky python3 python3-gobject-Gdk dejavu-fonts \
            || hinweis "Nicht alle Pakete installierbar"
    else
        hinweis "Unbekannte Paketverwaltung – gebraucht werden: conky, python3, python3-gi (GTK 3),"
        hinweis "die Schrift DejaVu Sans und möglichst Inter."
    fi
fi
hat conky   || { echo "Es fehlt: conky" >&2; exit 1; }
hat python3 || { echo "Es fehlt: python3" >&2; exit 1; }

# --- 2. Dateien ins Benutzerkonto ------------------------------------------------------
info "Skripte nach ~/.local/bin installieren"
mkdir -p "$BIN" "$DATEN" "$(dirname "$STARTER")" "$(dirname "$AUTOSTART")"
install -m755 "$REPO/conky/eierschecke-conky" "$REPO/conky/eierschecke-wetter" \
              "$REPO/conky/eierschecke-nachrichten" "$REPO/tools/widget-menue/eierschecke-widgets" "$BIN/"
# Das Python-Modul liegt neben den Skripten und wird so ohne weitere Einrichtung gefunden.
install -m644 "$REPO/conky/eierschecke_konfig.py" "$BIN/"
install -m644 "$REPO/conky/conkyrc.vorlage" "$DATEN/"

# Menüeintrag „Desktop-Widgets“ und Autostart – mit vollem Pfad, unabhängig vom PATH
sed -e "s|^Exec=.*|Exec=$BIN/eierschecke-widgets|" -e 's|^Icon=.*|Icon=preferences-desktop|' \
    "$REPO/tools/widget-menue/eierschecke-widgets.desktop" > "$STARTER"
sed -e "s|^Exec=.*|Exec=$BIN/eierschecke-conky start --autostart|" -e '/^OnlyShowIn=/d' -e '/^Icon=/d' \
    "$REPO/conky/eierschecke-conky.desktop" > "$AUTOSTART"

if ! python3 -c 'import gi; gi.require_version("Gtk", "3.0")' 2>/dev/null; then
    hinweis "Python-GTK fehlt – das Menü Desktop-Widgets startet nicht; das Widget selbst läuft."
fi
if ! fc-list : family 2>/dev/null | grep -qiw 'Inter'; then
    hinweis "Schrift Inter fehlt – Conky nimmt eine Ersatzschrift."
fi

# --- 3. Starten ---------------------------------------------------------------------------
if [ -n "${DISPLAY:-}" ]; then
    info "Widget starten"
    "$BIN/eierschecke-conky" restart
else
    hinweis "Keine grafische Sitzung erkannt – das Widget startet bei der nächsten Anmeldung."
fi

info "Fertig."
echo "    Einstellen:  Menü → Desktop-Widgets  (oder: $BIN/eierschecke-widgets)"
echo "    Von Hand:    ~/.config/eierschecke/conky.conf, danach: $BIN/eierschecke-conky restart"
echo "    Entfernen:   $0 --entfernen"
