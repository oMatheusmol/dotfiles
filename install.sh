#!/usr/bin/env bash

set -e

OS="$(uname -s)"
IS_WSL=false
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true

echo "==> forge install: OS=$OS, WSL=$IS_WSL"

# Install fd
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    echo "==> Installing fd..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install fd
    else
        sudo apt-get install -y fd-find
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi
fi

# Install ripgrep if missing
if ! command -v rg &>/dev/null; then
    echo "==> Installing ripgrep..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install ripgrep
    else
        sudo apt-get install -y ripgrep
    fi
fi

# Install fzf if missing
if ! command -v fzf &>/dev/null; then
    echo "==> Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# Undo directory for nvim
mkdir -p ~/.vim/undodir

# Backup and link nvim config
if [[ -d ~/.config/nvim && ! -L ~/.config/nvim ]]; then
    echo "==> Backing up existing nvim config..."
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
fi
mkdir -p ~/.config
ln -sfn ~/.dotfiles/nvim/.config/nvim ~/.config/nvim
echo "==> nvim config linked"

# Link tmux config
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
echo "==> tmux config linked"

# Install scripts to ~/.local/bin
mkdir -p ~/.local/bin
for script in ~/.dotfiles/bin/*; do
    chmod +x "$script"
    ln -sf "$script" ~/.local/bin/$(basename "$script")
    echo "==> Linked script: $(basename "$script")"
done

# Ensure ~/.local/bin is in PATH (add to zshrc if missing)
if ! grep -q 'local/bin' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "==> Added ~/.local/bin to PATH in .zshrc"
fi

echo ""
echo "  forge is ready."
echo "  Open nvim to bootstrap plugins automatically."
echo "  Source your shell: source ~/.zshrc"
