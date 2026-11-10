# Gemeinsame Funktionen der Build-Hooks (config/hooks/live). Nur beim Build genutzt.
. /usr/share/eierschecke/eierschecke.conf
. /usr/share/eierschecke/build.conf
WARNLOG=/var/log/eierschecke-build-warnungen.log
export DEBIAN_FRONTEND=noninteractive

warnung() {
    echo "W: $*" >&2
    echo "$*" >> "$WARNLOG"
}

# Installiert die Pakete einer Liste einzeln; "a | b" = erste installierbare Alternative.
installiere_liste() {
    while IFS= read -r zeile <&3; do
        zeile="${zeile%%#*}"
        [ -n "$(echo "$zeile" | tr -d '[:space:]')" ] || continue
        ok=0
        for paket in $(echo "$zeile" | tr '|' ' '); do
            if apt-get install -y "$paket"; then
                ok=1
                break
            fi
        done
        [ "$ok" = 1 ] || warnung "Paket nicht installierbar: $zeile"
    done 3< "$1"
}
