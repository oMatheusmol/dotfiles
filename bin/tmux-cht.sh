#!/usr/bin/env bash

# Languages and commands lists
languages=$(echo "golang rust python javascript typescript node" | tr ' ' '\n')
core_utils=$(echo "git curl wget jq awk sed grep find xargs tar ssh docker" | tr ' ' '\n')

selected=$(echo -e "$languages\n$core_utils" | fzf)

if [[ -z $selected ]]; then
    exit 0
fi

read -p "Query: " query

if echo "$languages" | grep -qs "$selected"; then
    query=$(echo "$query" | tr ' ' '+')
    tmux neww bash -c "curl -s 'cht.sh/$selected/$query' | less -R"
else
    tmux neww bash -c "curl -s 'cht.sh/$selected~$query' | less -R"
fi
