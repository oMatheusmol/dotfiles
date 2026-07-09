#!/usr/bin/env bash
# When you Cmd+C a file in Finder (image, video, anything), the clipboard
# holds a file reference, not text — pasting into a terminal does nothing.
# Run this right after copying the file: it converts the clipboard to the
# file's absolute POSIX path as plain text, so Cmd+V in a terminal works.
set -uo pipefail

path="$(osascript -e 'POSIX path of (the clipboard as «class furl»)' 2>/dev/null)"

if [ -n "$path" ]; then
    printf '%s' "$path" | pbcopy
    osascript -e "display notification \"$path\" with title \"Caminho copiado\"" >/dev/null 2>&1
else
    osascript -e 'display notification "Nenhum arquivo copiado no clipboard" with title "Erro"' >/dev/null 2>&1
fi
