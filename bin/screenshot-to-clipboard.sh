#!/usr/bin/env bash
# Interactive screenshot (drag to select an area, space to switch to window
# mode, esc to cancel). Saves the PNG and puts its absolute path as plain
# text on the clipboard, ready to paste into a terminal.
set -uo pipefail

DEST_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

screencapture -i "$DEST"

if [ -f "$DEST" ]; then
    printf '%s' "$DEST" | pbcopy
    osascript -e "display notification \"$DEST\" with title \"Screenshot salvo\"" >/dev/null 2>&1
else
    osascript -e 'display notification "Cancelado" with title "Screenshot"' >/dev/null 2>&1
fi
