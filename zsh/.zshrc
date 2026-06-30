# ── Platform detection ────────────────────────────────────────────────────────
IS_MACOS=false; IS_WSL=false; IS_LINUX=false
[[ "$(uname -s)" == "Darwin" ]] && IS_MACOS=true
[[ "$(uname -r)" == *microsoft* ]] && IS_WSL=true
[[ "$(uname -s)" == "Linux" ]] && IS_LINUX=true

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# macOS homebrew
if $IS_MACOS; then
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

# nvim (linux binary)
[[ -d "$HOME/.local/nvim-linux-x86_64/bin" ]] && export PATH="$HOME/.local/nvim-linux-x86_64/bin:$PATH"

# ── WSL clipboard ─────────────────────────────────────────────────────────────
if $IS_WSL; then
    export BROWSER="false"
fi

# ── Oh-My-Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX=true
ZSH_THEME=""

fpath+="$ZSH/custom/plugins/zsh-completions/src"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting history)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ── Oh-My-Posh ────────────────────────────────────────────────────────────────
command -v oh-my-posh &>/dev/null && eval "$(oh-my-posh init zsh --config ~/.dotfiles/gruber.omp.json)"

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# ── fzf ───────────────────────────────────────────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ── zoxide ────────────────────────────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── bun ───────────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias vim=nvim
command -v batcat &>/dev/null && alias bat="batcat"
alias zz="z -"
