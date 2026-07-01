#!/usr/bin/env bash
set -e

# ── Detecção de plataforma ────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=false
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true

echo "==> dotfiles | OS=$OS ARCH=$ARCH WSL=$IS_WSL"

# ── macOS ─────────────────────────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
    # Homebrew
    if ! command -v brew &>/dev/null; then
        echo "==> Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ "$ARCH" == "arm64" ]] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "==> brew bundle..."
    brew bundle --file ~/.dotfiles/Brewfile 2>/dev/null || true
fi

# ── Linux / WSL ───────────────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    echo "==> apt packages..."
    sudo apt-get update -q
    sudo apt-get install -y curl git zsh unzip ripgrep fd-find build-essential 2>/dev/null || true

    # fd symlink
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi

    # neovim
    if ! command -v nvim &>/dev/null; then
        echo "==> neovim..."
        curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz
        tar -C ~/.local -xzf /tmp/nvim.tar.gz
        rm /tmp/nvim.tar.gz
        mkdir -p ~/.local/bin
        ln -sf ~/.local/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim
    fi

    # Go
    if ! command -v go &>/dev/null || ! go version 2>/dev/null | grep -qE "go1\.(2[1-9]|[3-9][0-9])"; then
        echo "==> Go..."
        GO_VER=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1 | tr -d 'go')
        curl -fsSL "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
        rm -rf ~/.local/go && tar -C ~/.local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz
    fi
    export PATH="$HOME/.local/go/bin:$HOME/.local/bin:$PATH"

    # tmux
    command -v tmux &>/dev/null || sudo apt-get install -y tmux

    # fzf
    if ! command -v fzf &>/dev/null; then
        echo "==> fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    fi

    # zoxide
    if ! command -v zoxide &>/dev/null; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    # oh-my-posh
    if ! command -v oh-my-posh &>/dev/null; then
        echo "==> oh-my-posh..."
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    fi
fi

# ── zsh como shell padrão ─────────────────────────────────────────────────────
if [[ "$SHELL" != *zsh ]]; then
    echo "==> Setting zsh as default shell..."
    ZSH_PATH=$(command -v zsh)
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
    chsh -s "$ZSH_PATH"
fi

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "==> oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ── NVM ───────────────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "==> nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts
fi

# ── Rust ──────────────────────────────────────────────────────────────────────
if ! command -v rustup &>/dev/null; then
    echo "==> Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

# ── Symlinks ──────────────────────────────────────────────────────────────────
mkdir -p ~/.vim/undodir ~/.config ~/.local/bin

# nvim
if [[ -d ~/.config/nvim && ! -L ~/.config/nvim ]]; then
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
fi
ln -sfn ~/.dotfiles/nvim/.config/nvim ~/.config/nvim
echo "==> nvim linked"

# tmux
ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
echo "==> tmux linked"

# zshrc (substitui o existente pelo do dotfiles)
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
echo "==> zshrc linked"

# gitconfig
ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
echo "==> gitconfig linked"

# ghostty (macOS)
if [[ "$OS" == "Darwin" ]]; then
    mkdir -p ~/.config/ghostty
    ln -sf ~/.dotfiles/ghostty/.config/ghostty/config ~/.config/ghostty/config
    echo "==> ghostty linked"
fi

# scripts
for script in ~/.dotfiles/bin/*; do
    chmod +x "$script"
    ln -sf "$script" ~/.local/bin/$(basename "$script")
done
echo "==> scripts linked"

# ── Bootstrap nvim plugins ────────────────────────────────────────────────────
echo "==> nvim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

echo ""
echo "  Done! Run: source ~/.zshrc"
