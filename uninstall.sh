#!/usr/bin/env bash
# Desfaz o que o install.sh symlinkou, restaurando o que existia antes
# (arquivos movidos para "<caminho>.pre-dotfiles" pelo install.sh).
#
# NÃO remove pacotes instalados via brew/apt/nvm/rustup/TPM/pip/etc — isso é
# aditivo e não sobrescreve nada de quem já usava a máquina, então fica.
set -uo pipefail

restore() {
    local target="$1"
    if [[ -L "$target" ]]; then
        rm "$target"
        echo "removido:    $target"
    fi
    if [[ -e "$target.pre-dotfiles" ]]; then
        mv "$target.pre-dotfiles" "$target"
        echo "restaurado:  $target"
    fi
}

echo "==> Desfazendo symlinks do dotfiles..."

restore ~/.config/nvim
restore ~/.tmux.conf
restore ~/.zshrc
restore ~/.gitconfig
restore ~/.config/ghostty/config
restore ~/.skhdrc
restore ~/.claude/settings.json
restore ~/.claude/commands
restore ~/.claude/hooks

for script in ~/.dotfiles/bin/*; do
    restore "$HOME/.local/bin/$(basename "$script")"
done

echo ""
echo "  Pronto. Configs originais restauradas (onde existia um '.pre-dotfiles')."
echo "  Pacotes instalados (brew/apt/nvm/rustup/TPM/piper/etc) não foram removidos —"
echo "  são aditivos, não sobrescrevem nada de quem já usava a máquina."
