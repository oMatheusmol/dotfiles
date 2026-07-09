#!/usr/bin/env bash

input=$(cat)
transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

if [ -z "$transcript_path" ] || [ -z "$cwd" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

mkdir -p "$cwd/.claude"

jq -s -r '
  ([.[] | select(.type=="assistant")] | last // {}) as $m
  | ($m.message.content // [])
  | map(select(.type=="text") | .text)
  | join("\n\n")
' "$transcript_path" > "$cwd/.claude/last_message.md"
