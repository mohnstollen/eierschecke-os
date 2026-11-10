"""Gemeinsame Abfragen des EierscheckeOS Update-Centers (ohne Root-Rechte)."""
import os
import shutil
import subprocess

BACKEND = "/usr/libexec/eierschecke/update-backend"
FLATPAK_TIMER = "eierschecke-flatpak-update.timer"


def _ausgabe(befehl, timeout=180):
    try:
        ergebnis = subprocess.run(befehl, capture_output=True, text=True, timeout=timeout,
                                  env=dict(os.environ, LC_ALL="C"))
        return ergebnis.stdout if ergebnis.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def _aktiviert(einheit):
    try:
        return subprocess.run(["systemctl", "is-enabled", "--quiet", einheit]).returncode == 0
    except OSError:
        return False


def snap_aktiv():
    return shutil.which("snap") is not None and _aktiviert("snapd.socket")


def flatpak_auto_aktiv():
    return _aktiviert(FLATPAK_TIMER)


def apt_anzahl():
    """Anzahl aktualisierbarer Pakete laut der zuletzt geladenen Paketlisten."""
    ausgabe = _ausgabe(["apt-get", "-s", "-o", "Debug::NoLocking=true", "full-upgrade"])
    return sum(1 for zeile in ausgabe.splitlines() if zeile.startswith("Inst "))


def flatpak_anzahl():
    if shutil.which("flatpak") is None:
        return 0
    ausgabe = _ausgabe(["flatpak", "remote-ls", "--updates", "--system", "--columns=application"])
    return sum(1 for zeile in ausgabe.splitlines() if zeile.strip())


def snap_anzahl():
    if not snap_aktiv():
        return 0
    zeilen = [z for z in _ausgabe(["snap", "refresh", "--list"]).splitlines() if z.strip()]
    return max(0, len(zeilen) - 1)  # erste Zeile ist die Kopfzeile


def anzahl():
    """Gibt (gesamt, Beschreibung) zurück."""
    teile = (("Pakete", apt_anzahl()), ("Flatpaks", flatpak_anzahl()), ("Snaps", snap_anzahl()))
    gesamt = sum(n for _, n in teile)
    beschreibung = ", ".join(f"{n} {name}" for name, n in teile if n)
    return gesamt, beschreibung
