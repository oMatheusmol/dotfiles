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
    sudo apt-get install -y curl git zsh unzip ripgrep fd-find build-essential mpv 2>/dev/null || true

    # Python 3.11 (Piper TTS venv — onnxruntime/piper-phonemize wheels lag
    # newer pythons, so this is kept separate from the line above: if the
    # package name doesn't exist on this distro, it must not take the rest
    # of the apt install down with it)
    if ! command -v python3.11 &>/dev/null; then
        echo "==> python3.11..."
        sudo apt-get install -y python3.11 python3.11-venv 2>/dev/null || echo "!! python3.11 unavailable, Piper voice setup will be skipped"
    fi

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

# ── Piper TTS (voz local para /say e o `R` do copy-mode do tmux) ─────────────
PIPER_HOME="$HOME/.local/share/piper"
if [[ ! -x "$PIPER_HOME/venv/bin/piper" ]]; then
    echo "==> Piper TTS..."
    PY311="$(command -v python3.11 || true)"
    if [[ -n "$PY311" ]]; then
        mkdir -p "$PIPER_HOME/voices"
        "$PY311" -m venv "$PIPER_HOME/venv"
        "$PIPER_HOME/venv/bin/pip" install --quiet --upgrade pip
        "$PIPER_HOME/venv/bin/pip" install --quiet piper-tts \
            || echo "!! piper-tts install failed — /say and tmux R won't have voice"
    else
        echo "!! python3.11 not found — skipping Piper (install it manually later for /say voice)"
    fi
fi

if [[ -x "$PIPER_HOME/venv/bin/piper" ]]; then
    echo "==> Piper voice models..."
    VOICES_BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main"
    fetch_voice() {
        local url="$1" dest="$2"
        [[ -f "$dest" ]] || curl -fsSL -o "$dest" "$url"
    }
    fetch_voice "$VOICES_BASE/pt/pt_BR/faber/medium/pt_BR-faber-medium.onnx" "$PIPER_HOME/voices/pt_BR-faber-medium.onnx"
    fetch_voice "$VOICES_BASE/pt/pt_BR/faber/medium/pt_BR-faber-medium.onnx.json" "$PIPER_HOME/voices/pt_BR-faber-medium.onnx.json"
    fetch_voice "$VOICES_BASE/en/en_US/ryan/high/en_US-ryan-high.onnx" "$PIPER_HOME/voices/en_US-ryan-high.onnx"
    fetch_voice "$VOICES_BASE/en/en_US/ryan/high/en_US-ryan-high.onnx.json" "$PIPER_HOME/voices/en_US-ryan-high.onnx.json"
fi

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

# skhd (macOS only — global hotkeys for screenshot-to-path / file-to-path)
if [[ "$OS" == "Darwin" ]]; then
    ln -sf ~/.dotfiles/skhd/.skhdrc ~/.skhdrc
    echo "==> skhd linked"
    if command -v skhd &>/dev/null; then
        brew services restart skhd 2>/dev/null || true
    fi
    echo "!! skhd precisa de permissao de Accessibility (System Settings > Privacy & Security > Accessibility)"
    echo "!! screencapture precisa de permissao de Screen Recording pro processo que rodar skhd"
fi

# scripts
for script in ~/.dotfiles/bin/*; do
    chmod +x "$script"
    ln -sf "$script" ~/.local/bin/$(basename "$script")
done
echo "==> scripts linked"

# claude code (global config: hooks, custom commands, settings)
mkdir -p ~/.claude
ln -sf ~/.dotfiles/claude/settings.json ~/.claude/settings.json
ln -sfn ~/.dotfiles/claude/commands ~/.claude/commands
ln -sfn ~/.dotfiles/claude/hooks ~/.claude/hooks
echo "==> claude code config linked"

# ── Bootstrap nvim plugins ────────────────────────────────────────────────────
echo "==> nvim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

# ── tmux plugins (TPM) ────────────────────────────────────────────────────────
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo "==> TPM..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
fi
if [[ -x ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
    ~/.tmux/plugins/tpm/bin/install_plugins 2>/dev/null || true
fi
# tmux-which-key's config.yaml lives inside the plugin's own repo, so a fresh
# TPM clone would come back with the plugin's defaults — overwrite it with
# our tracked customization (the +Fala menu, sessionizer, cheatsheet, etc).
if [[ -f ~/.tmux/plugins/tmux-which-key/config.yaml ]]; then
    cp ~/.dotfiles/tmux/which-key-config.yaml ~/.tmux/plugins/tmux-which-key/config.yaml
    echo "==> which-key config applied"
fi

echo ""
echo "  Done! Run: source ~/.zshrc"
