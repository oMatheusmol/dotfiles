#!/usr/bin/env bash

set -e

OS="$(uname -s)"
IS_WSL=false
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true

echo "==> dotfiles install: OS=$OS, WSL=$IS_WSL"

# macOS: install brew dependencies
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        echo "==> Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "==> Installing dependencies via brew..."
    brew install neovim tmux ripgrep fzf fd git oh-my-posh go 2>/dev/null || true
fi

# Linux: install fd
if [[ "$OS" == "Linux" ]]; then
    if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
        echo "==> Installing fd..."
        sudo apt-get install -y fd-find
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi
    if ! command -v rg &>/dev/null; then
        sudo apt-get install -y ripgrep
    fi
    if ! command -v fzf &>/dev/null; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    fi
    if ! command -v oh-my-posh &>/dev/null; then
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    fi
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

# Add PATH and oh-my-posh to zshrc if missing
ZSHRC="$HOME/.zshrc"

if ! grep -q 'local/bin' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

if ! grep -q 'oh-my-posh' "$ZSHRC" 2>/dev/null; then
    echo 'eval "$(oh-my-posh init zsh --config ~/.dotfiles/gruber.omp.json)"' >> "$ZSHRC"
    echo "==> oh-my-posh added to zshrc"
fi

# macOS: add brew Go to PATH
if [[ "$OS" == "Darwin" ]] && ! grep -q 'go/bin' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$PATH:$(brew --prefix go)/bin"' >> "$ZSHRC"
fi

echo ""
echo "  dotfiles installed."
echo "  Open nvim to bootstrap plugins automatically."
echo "  Run: source ~/.zshrc"
