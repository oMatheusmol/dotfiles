#!/usr/bin/env bash
set -uo pipefail

PIPER_BIN="$HOME/.local/share/piper/venv/bin/piper"
VOICES="$HOME/.local/share/piper/voices"
PT_MODEL="$VOICES/pt_BR-faber-medium.onnx"
EN_MODEL="$VOICES/en_US-ryan-high.onnx"
SOCK=/tmp/claude-speak.sock

lang=""
if [ "${1:-}" = "--lang" ]; then
  lang="$2"
  shift 2
fi

if [ -n "${1:-}" ] && [ -f "$1" ]; then
  text=$(cat "$1")
else
  text=$(cat)
fi

# Collapse full paths to just the last segment (2+ slashes, so "e/ou" survives)
# and strip markdown/code noise that reads badly out loud.
clean=$(printf '%s' "$text" \
  | perl -pe 's{https?://\S+}{um link}g' \
  | perl -pe 's{(?:[~\w.\-]*/){2,}([\w.\-]+)}{$1}g' \
  | perl -pe 's/```[a-zA-Z]*/ bloco de codigo /g; s/```//g' \
  | perl -pe 's/\*\*([^*]+)\*\*/$1/g; s/__([^_]+)__/$1/g' \
  | perl -pe 's/`([^`]+)`/$1/g' \
  | perl -pe 's/^#+\s*//gm' \
  | perl -pe 's/^[-*]\s+/ /gm' \
  | perl -pe 's/\[([^\]]+)\]\([^)]+\)/$1/g')

if [ -z "$lang" ]; then
  pt_hits=$(printf '%s' "$clean" | grep -oiE '[áàâãéêíóôõúç]|\b(nao|voce|para|com|uma|isso|entao|esta|tambem|muito|ola|obrigado|arquivo|projeto|que|nao)\b' | wc -l | tr -d ' ')
  en_hits=$(printf '%s' "$clean" | grep -oiE '\b(the|and|is|of|to|in|that|this|with|for|you|your)\b' | wc -l | tr -d ' ')
  if [ "$pt_hits" -ge "$en_hits" ]; then
    lang="pt"
  else
    lang="en"
  fi
fi

if [ "$lang" = "pt" ]; then
  model="$PT_MODEL"
else
  model="$EN_MODEL"
fi

wav="$(mktemp -t claude-speak).wav"
printf '%s' "$clean" | "$PIPER_BIN" -m "$model" -f "$wav" >/dev/null 2>&1

rm -f "$SOCK"
mpv --input-ipc-server="$SOCK" --no-video --no-terminal --really-quiet "$wav"
rm -f "$wav" "$SOCK"
