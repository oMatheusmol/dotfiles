#!/usr/bin/env bash

set -e

OS="$(uname -s)"
IS_WSL=false
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true

echo "==> dotfiles install: OS=$OS, WSL=$IS_WSL"

# ── Homebrew (macOS) ─────────────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        echo "==> Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo "==> Installing brew packages..."
    brew install neovim tmux ripgrep fzf fd git go oh-my-posh zsh 2>/dev/null || true
fi

# ── apt packages (Linux/WSL) ─────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    echo "==> Installing apt packages..."
    sudo apt-get update -q
    sudo apt-get install -y git curl zsh ripgrep fd-find unzip 2>/dev/null || true

    # fd symlink
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi

    # fzf
    if ! command -v fzf &>/dev/null; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    fi

    # oh-my-posh
    if ! command -v oh-my-posh &>/dev/null; then
        echo "==> Installing oh-my-posh..."
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    fi

    # Go
    if ! command -v go &>/dev/null || [[ "$($HOME/.local/go/bin/go version 2>/dev/null | awk '{print $3}' | tr -d 'go')" < "1.21" ]]; then
        echo "==> Installing Go..."
        GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1 | tr -d 'go')
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
        rm -rf ~/.local/go
        tar -C ~/.local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
    fi

    # neovim
    if ! command -v nvim &>/dev/null; then
        echo "==> Installing neovim..."
        curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz
        tar -C ~/.local -xzf /tmp/nvim.tar.gz
        rm /tmp/nvim.tar.gz
        mkdir -p ~/.local/bin
        ln -sf ~/.local/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim
    fi
fi

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "==> Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ── Symlinks ──────────────────────────────────────────────────────────────────
mkdir -p ~/.vim/undodir ~/.config ~/.local/bin

# nvim
if [[ -d ~/.config/nvim && ! -L ~/.config/nvim ]]; then
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
fi
ln -sfn ~/.dotfiles/nvim/.config/nvim ~/.config/nvim
echo "==> nvim config linked"

# tmux
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
echo "==> tmux config linked"

# scripts
for script in ~/.dotfiles/bin/*; do
    chmod +x "$script"
    ln -sf "$script" ~/.local/bin/$(basename "$script")
done
echo "==> scripts linked"

# ── zshrc ─────────────────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"

# Garante que o bloco do dotfiles existe no zshrc
if ! grep -q 'dotfiles config' "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" << 'EOF'

# ── dotfiles config ───────────────────────────────────────────────────────────
export ZSH_DISABLE_COMPFIX=true
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

# macOS: homebrew Go
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"

# neovim
[[ -d /opt/nvim-linux-x86_64/bin ]] && export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.dotfiles/gruber.omp.json)"
# ─────────────────────────────────────────────────────────────────────────────
EOF
    echo "==> zshrc updated"
fi

# ── Bootstrap nvim plugins ───────────────────────────────────────────────────
echo "==> Bootstrapping nvim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

echo ""
echo "  Done. Run: source ~/.zshrc"
