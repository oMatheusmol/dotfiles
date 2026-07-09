#!/usr/bin/env bash
set -e

# ── Detecção de plataforma ────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=false
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true

echo "==> dotfiles | OS=$OS ARCH=$ARCH WSL=$IS_WSL"

# Go names releases amd64/arm64, Neovim names releases x86_64/arm64, but
# `uname -m` reports x86_64/aarch64 — normalize once here instead of
# hardcoding one architecture in each download below.
GO_ARCH="amd64"; NVIM_ARCH="x86_64"
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    GO_ARCH="arm64"; NVIM_ARCH="arm64"
fi

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
    # Prepend early so every version check below (nvim, go) sees anything we
    # install into ~/.local/bin ahead of an older apt-installed binary on PATH.
    export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"

    echo "==> apt packages..."
    sudo apt-get update -q
    # ncurses-term provides the tmux-256color terminfo entry — without it,
    # tmux.conf's `default-terminal "tmux-256color"` would break instead of
    # fix truecolor/theme rendering on a minimal WSL/Ubuntu install.
    sudo apt-get install -y curl git zsh unzip ripgrep fd-find build-essential mpv software-properties-common ncurses-term 2>/dev/null || true

    # Python 3.11 (Piper TTS venv — onnxruntime/piper-phonemize wheels lag
    # newer pythons, so this is kept separate from the line above: if the
    # package name doesn't exist on this distro, it must not take the rest
    # of the apt install down with it). Same cascade shape as neovim above:
    # default repos -> deadsnakes PPA -> build from source, each only
    # attempted if the previous one didn't yield a working python3.11
    # (deadsnakes stopped building it for old releases like Ubuntu 20.04,
    # same story as the neovim PPA dropping focal support).
    if ! command -v python3.11 &>/dev/null; then
        echo "==> python3.11..."
        sudo apt-get install -y python3.11 python3.11-venv 2>/dev/null || true
    fi

    if ! command -v python3.11 &>/dev/null && grep -qi ubuntu /etc/os-release 2>/dev/null; then
        sudo add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
        sudo apt-get update -q
        sudo apt-get install -y python3.11 python3.11-venv 2>/dev/null || true
    fi

    if ! command -v python3.11 &>/dev/null; then
        echo "==> python3.11 (building from source — not available via apt or deadsnakes for this release)..."
        sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
            libsqlite3-dev libffi-dev liblzma-dev 2>/dev/null || true
        PY_VER=3.11.9
        rm -rf /tmp/python-src && mkdir -p /tmp/python-src
        curl -fsSL "https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz" -o /tmp/python.tgz
        tar -C /tmp/python-src --strip-components=1 -xzf /tmp/python.tgz 2>/dev/null || true
        rm -f /tmp/python.tgz
        if [ -f /tmp/python-src/configure ]; then
            (cd /tmp/python-src \
                && ./configure --prefix="$HOME/.local/python3.11" >/dev/null \
                && make -j"$(nproc)" >/dev/null \
                && make altinstall >/dev/null) || true
            [ -x "$HOME/.local/python3.11/bin/python3.11" ] && ln -sf "$HOME/.local/python3.11/bin/python3.11" ~/.local/bin/python3.11
        fi
        rm -rf /tmp/python-src
    fi

    command -v python3.11 &>/dev/null || echo "!! python3.11 unavailable, Piper voice setup will be skipped"

    # fd symlink
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
    fi

    # neovim — this config needs >=0.10 to do anything useful (lazy.nvim +
    # modern Lua APIs; treesitter's main branch wants 0.12+). Try
    # increasingly aggressive methods, checking the ACTUAL installed version
    # after each one — `command -v nvim` alone isn't enough, since e.g. the
    # neovim PPA doesn't build for Ubuntu 20.04 anymore and apt silently
    # falls back to the distro's own ancient 0.4.3 package instead.
    nvim_new_enough() {
        command -v nvim &>/dev/null || return 1
        local line major minor
        line=$(nvim --version 2>/dev/null | head -1)
        major=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
        minor=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f2)
        [ -n "$major" ] || return 1
        [ "$major" -gt 0 ] && return 0
        [ "${minor:-0}" -ge 10 ]
    }

    if ! nvim_new_enough; then
        echo "==> neovim (PPA)..."
        if grep -qi ubuntu /etc/os-release 2>/dev/null; then
            sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
            sudo apt-get update -q
            sudo apt-get install -y neovim 2>/dev/null || true
        fi
    fi

    if ! nvim_new_enough; then
        echo "==> neovim (prebuilt binary)..."
        rm -rf "$HOME/.local/nvim-linux-${NVIM_ARCH}"
        curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" -o /tmp/nvim.tar.gz
        tar -C ~/.local -xzf /tmp/nvim.tar.gz 2>/dev/null || true
        rm -f /tmp/nvim.tar.gz
        mkdir -p ~/.local/bin
        [ -x "$HOME/.local/nvim-linux-${NVIM_ARCH}/bin/nvim" ] && ln -sf "$HOME/.local/nvim-linux-${NVIM_ARCH}/bin/nvim" ~/.local/bin/nvim
    fi

    if ! nvim_new_enough; then
        # Last resort: neither the PPA nor the prebuilt binary yielded a
        # compatible+new-enough nvim (e.g. Ubuntu 20.04: PPA dropped focal
        # support, and the prebuilt binary needs a newer glibc than 20.04
        # ships). Building from source links against whatever glibc is
        # actually on this machine, so it always works, just slower.
        echo "==> neovim (building from source — takes a few minutes)..."
        sudo apt-get install -y ninja-build gettext cmake pkg-config 2>/dev/null || true
        rm -rf /tmp/neovim-src
        git clone --depth 1 https://github.com/neovim/neovim /tmp/neovim-src
        (cd /tmp/neovim-src && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$HOME/.local/nvim-src" install)
        mkdir -p ~/.local/bin
        ln -sf "$HOME/.local/nvim-src/bin/nvim" ~/.local/bin/nvim
        rm -rf /tmp/neovim-src
    fi

    # Go
    if ! command -v go &>/dev/null || ! go version 2>/dev/null | grep -qE "go1\.(2[1-9]|[3-9][0-9])"; then
        echo "==> Go..."
        GO_VER=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1 | tr -d 'go')
        curl -fsSL "https://go.dev/dl/go${GO_VER}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz
        rm -rf ~/.local/go && tar -C ~/.local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz
    fi
    export PATH="$HOME/.local/go/bin:$HOME/.local/bin:$PATH"

    # tmux
    command -v tmux &>/dev/null || sudo apt-get install -y tmux

    # fzf — `git clone` refuses to clone into a non-empty ~/.fzf (leftover
    # from a previous partial run, or a manual install), which would abort
    # the whole script since it runs with `set -e`. Only clone if missing;
    # always (re-)run install so the keybindings/completion get wired up.
    if ! command -v fzf &>/dev/null; then
        echo "==> fzf..."
        [[ -d ~/.fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish 2>/dev/null || true
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
    chsh -s "$ZSH_PATH" || echo "!! chsh failed (wrong password?) — run 'chsh -s $ZSH_PATH' yourself later"
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
fi
# Source regardless of whether nvm was just installed or already there, so
# `npm` is on PATH for the tree-sitter-cli step below even on a re-run.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
command -v node &>/dev/null || nvm install --lts

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo "==> Claude Code CLI..."
    curl -fsSL https://claude.ai/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
fi

# ── Rust ──────────────────────────────────────────────────────────────────────
if ! command -v rustup &>/dev/null; then
    echo "==> Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

# ── tree-sitter CLI ───────────────────────────────────────────────────────────
# nvim-treesitter's main branch shells out to the standalone `tree-sitter`
# CLI to compile parsers (`tree-sitter build`) — build-essential/gcc alone
# isn't enough. npm ships a prebuilt binary (fast, no compile), but on an
# older glibc (e.g. Ubuntu 20.04) that binary can't even run — same story as
# neovim/python3.11 above. cargo compiles it locally, so it always works.
tree_sitter_works() {
    command -v tree-sitter &>/dev/null && tree-sitter --version &>/dev/null
}

if ! tree_sitter_works; then
    echo "==> tree-sitter-cli (npm)..."
    npm install -g tree-sitter-cli 2>/dev/null || true
fi

if ! tree_sitter_works; then
    echo "==> tree-sitter-cli (building via cargo — prebuilt binary doesn't run on this system's glibc)..."
    if command -v cargo &>/dev/null; then
        cargo install tree-sitter-cli --locked 2>/dev/null || cargo install tree-sitter-cli 2>/dev/null || true
    fi
fi

tree_sitter_works || echo "!! tree-sitter-cli unavailable — nvim-treesitter parser installs will fail"

# ── TypeScript (global) ───────────────────────────────────────────────────────
# Mason bundles `typescript` alongside typescript-language-server for ts_ls,
# but on a fresh machine that install runs async on first nvim launch — if
# you open a .ts file before it finishes (or it falls back before finding the
# bundled copy), ts_ls errors with "Could not find a valid TypeScript
# installation". A global install is a fallback tsserver can always find,
# independent of Mason's timing or any given project's own node_modules.
#
# Pinned to the 5.x line on purpose: plain `typescript` now resolves to the
# 7.x native-port rewrite, which dropped lib/tsserver.js entirely — the
# classic typescript-language-server (ts_ls) can't use it at all.
if ! command -v tsc &>/dev/null; then
    echo "==> typescript (global)..."
    npm install -g typescript@5 2>/dev/null || true
fi

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

# Symlinks $2 (a dotfiles path) onto $1 (a $HOME path). If $1 already exists
# as a REAL file/dir (not one of our own symlinks), it's moved to
# "$1.pre-dotfiles" first — uninstall.sh looks for that exact suffix to put
# it back. Safe to re-run: once $1 is our symlink, nothing gets backed up
# again.
link_with_backup() {
    local target="$1" source="$2"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mv "$target" "$target.pre-dotfiles"
    fi
    if [[ -d "$source" ]]; then
        ln -sfn "$source" "$target"
    else
        ln -sf "$source" "$target"
    fi
}

# nvim
link_with_backup ~/.config/nvim ~/.dotfiles/nvim/.config/nvim
echo "==> nvim linked"

# tmux
link_with_backup ~/.tmux.conf ~/.dotfiles/tmux/.tmux.conf
echo "==> tmux linked"

# zshrc
link_with_backup ~/.zshrc ~/.dotfiles/zsh/.zshrc
echo "==> zshrc linked"

# gitconfig
link_with_backup ~/.gitconfig ~/.dotfiles/git/.gitconfig
echo "==> gitconfig linked"

# ghostty (macOS)
if [[ "$OS" == "Darwin" ]]; then
    mkdir -p ~/.config/ghostty
    link_with_backup ~/.config/ghostty/config ~/.dotfiles/ghostty/.config/ghostty/config
    echo "==> ghostty linked"
fi

# skhd (macOS only — global hotkeys for screenshot-to-path / file-to-path)
if [[ "$OS" == "Darwin" ]]; then
    link_with_backup ~/.skhdrc ~/.dotfiles/skhd/.skhdrc
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
    link_with_backup "$HOME/.local/bin/$(basename "$script")" "$script"
done
echo "==> scripts linked"

# claude code (global config: hooks, custom commands, settings)
mkdir -p ~/.claude
link_with_backup ~/.claude/settings.json ~/.dotfiles/claude/settings.json
link_with_backup ~/.claude/commands ~/.dotfiles/claude/commands
link_with_backup ~/.claude/hooks ~/.dotfiles/claude/hooks
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
