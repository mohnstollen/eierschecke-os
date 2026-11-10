# Fremdquellen

Diese Dateien werden **nicht** über den `archives`-Mechanismus von live-build
eingebunden, sondern von `build.sh` direkt ins System gelegt. So liegen die
Quellen genau dort, wo die Hersteller sie selbst erwarten (wichtig, weil z. B.
Brave und Claude Desktop ihre Quelle sonst ein zweites Mal eintragen).

| Datei | Zweck |
|---|---|
| `*.sources`, `*.list` | APT-Quelle → `/etc/apt/sources.list.d/` |
| `*.pref` | APT-Pinning → `/etc/apt/preferences.d/` |
| `schluessel.conf` | Signaturschlüssel: Download-Adresse, Ablageort, Fingerabdruck |
| `fremdpakete.pakete` | Pakete, die der Hook `0100-fremdquellen` aus diesen Quellen installiert |

Die Schlüssel werden bei jedem Build frisch vom Hersteller geladen. Ist in
`schluessel.conf` ein Fingerabdruck eingetragen, bricht der Build bei einer
Abweichung ab.
