"""Gemeinsame Konfiguration der EierscheckeOS-Desktop-Widgets.

Die Datei ~/.config/eierschecke/conky.conf enthält einfache SCHLÜSSEL=Wert-Zeilen.
"""
import os

KONFIG_DATEI = os.path.expanduser("~/.config/eierschecke/conky.conf")
CACHE_ORDNER = os.path.expanduser("~/.cache/eierschecke")

STANDARD = {
    "WIDGETS": "an",
    "ORT_NAME": "Herzogenaurach",
    "ORT_BREITE": "49.57",
    "ORT_LAENGE": "10.88",
    "WETTER": "an",
    "WETTER_INTERVALL_MIN": "30",
    "NACHRICHTEN": "an",
    "NACHRICHTEN_INTERVALL_MIN": "15",
    "NACHRICHTEN_ANZAHL": "7",
    "SYSTEM": "an",
}

KOPF = """# EierscheckeOS – Desktop-Widgets (Conky)
# Bearbeiten über das Menü „Desktop-Widgets“ oder von Hand; danach: eierschecke-conky restart
"""


def laden():
    werte = dict(STANDARD)
    try:
        with open(KONFIG_DATEI, encoding="utf-8") as datei:
            for zeile in datei:
                zeile = zeile.strip()
                if not zeile or zeile.startswith("#") or "=" not in zeile:
                    continue
                schluessel, wert = zeile.split("=", 1)
                werte[schluessel.strip()] = wert.strip().strip('"')
    except OSError:
        pass
    return werte


def speichern(werte):
    os.makedirs(os.path.dirname(KONFIG_DATEI), exist_ok=True)
    with open(KONFIG_DATEI, "w", encoding="utf-8") as datei:
        datei.write(KOPF)
        for schluessel in STANDARD:
            datei.write(f"{schluessel}={werte.get(schluessel, STANDARD[schluessel])}\n")


def an(werte, schluessel):
    return werte.get(schluessel, "an").lower() in ("an", "ja", "1", "true", "on")


def zahl(werte, schluessel, minimum, maximum):
    try:
        wert = int(float(werte.get(schluessel, STANDARD[schluessel])))
    except ValueError:
        wert = int(STANDARD[schluessel])
    return max(minimum, min(maximum, wert))


def conky_text(text):
    """Entschärft Zeichen, die Conky sonst als Befehle deutet."""
    return text.replace("\\", "/").replace("$", "$$").replace("#", "\\#")
