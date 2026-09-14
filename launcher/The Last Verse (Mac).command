#!/bin/bash
# The Last Verse – Launcher für Spieltester (macOS)
# Lädt beim ersten Start die Godot-Laufzeit und das Spiel aus dem GitHub-Repository,
# holt bei jedem weiteren Start automatisch die neueste Version und startet das Spiel.

REPO="mrkderchef/thelastverse"
BRANCH="main"
GODOT_VERSION="4.7.2-stable"
DIR="${TLV_HOME:-$HOME/Library/Application Support/TheLastVerseLauncher}"

set -u
mkdir -p "$DIR" && cd "$DIR" || exit 1

echo ""
echo "  THE LAST VERSE  ·  Shakespeare and London Times"
echo "  ------------------------------------------------"
echo ""

fail() {
	echo ""
	echo "  !! $1"
	echo ""
	read -r -p "  Enter drücken zum Schließen …" _
	exit 1
}

# 1. Die Godot-Laufzeit (einmalig, ca. 70 MB).
GODOT="$DIR/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT" ]; then
	echo "  Lade die Spiel-Engine (einmalig) …"
	curl -L --fail --progress-bar -o godot.zip "https://github.com/godotengine/godot-builds/releases/download/$GODOT_VERSION/Godot_v${GODOT_VERSION}_macos.universal.zip" || fail "Download der Engine fehlgeschlagen. Internetverbindung prüfen."
	rm -rf Godot.app
	unzip -q godot.zip && rm -f godot.zip
	xattr -dr com.apple.quarantine Godot.app 2>/dev/null
	[ -x "$GODOT" ] || fail "Die Engine konnte nicht entpackt werden."
fi

# 2. Die neueste Spielversion aus dem Repository.
LATEST=$(curl -fsSL "https://api.github.com/repos/$REPO/commits/$BRANCH" 2>/dev/null | grep -m1 '"sha"' | cut -d'"' -f4)
CURRENT=$(cat version.txt 2>/dev/null)
IMPORT=0
if [ -n "$LATEST" ] && [ "$LATEST" != "$CURRENT" ]; then
	if [ -d game ]; then echo "  Neue Version gefunden – wird geladen …"; else echo "  Lade das Spiel …"; fi
	curl -L --fail --progress-bar -o game.zip "https://codeload.github.com/$REPO/zip/refs/heads/$BRANCH" || fail "Download des Spiels fehlgeschlagen."
	rm -rf unpacked && mkdir unpacked
	unzip -q game.zip -d unpacked && rm -f game.zip
	NEW=$(find unpacked -mindepth 1 -maxdepth 1 -type d | head -1)
	[ -f "$NEW/project.godot" ] || fail "Das heruntergeladene Spiel ist unvollständig."
	# The import cache is kept so updates only re-import what changed.
	[ -d game/.godot ] && mv game/.godot "$NEW/.godot"
	rm -rf game && mv "$NEW" game && rm -rf unpacked
	echo "$LATEST" > version.txt
	IMPORT=1
elif [ -z "$LATEST" ]; then
	echo "  (Keine Verbindung zu GitHub – starte die zuletzt geladene Version.)"
fi
[ -f game/project.godot ] || fail "Das Spiel ist noch nicht geladen. Beim ersten Start wird Internet benötigt."

# 3. Vorbereiten (nach jedem Update) und starten.
if [ "$IMPORT" = 1 ] || [ ! -d game/.godot/imported ]; then
	echo "  Bereite das Spiel vor … (beim ersten Mal 1–3 Minuten)"
	"$GODOT" --headless --path "$DIR/game" --import >/dev/null 2>&1
fi

if [ "${TLV_NO_LAUNCH:-0}" = 1 ]; then
	echo "  Bereit (Start übersprungen)."
	exit 0
fi
echo "  Viel Spaß! Das Fenster öffnet sich gleich – dieses Terminal kann geschlossen werden."
open -n "$DIR/Godot.app" --args --path "$DIR/game"
exit 0
