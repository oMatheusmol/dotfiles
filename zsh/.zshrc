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

# nvim (linux binary, arch-agnostic — installed as nvim-linux-x86_64 or nvim-linux-arm64)
for _nvim_dir in "$HOME"/.local/nvim-linux-*/bin; do
    [[ -d "$_nvim_dir" ]] && export PATH="$_nvim_dir:$PATH"
done
unset _nvim_dir

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

# fzf: usa fd como fonte + previews coloridos (Ctrl-T arquivos, Alt-C pastas)
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
_fzf_bat=""; whence -p bat &>/dev/null && _fzf_bat=bat; whence -p batcat &>/dev/null && _fzf_bat=batcat
[[ -n "$_fzf_bat" ]] && export FZF_CTRL_T_OPTS="--preview '$_fzf_bat --color=always --style=numbers --line-range=:300 {}'"
command -v eza &>/dev/null && export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {}'"

# ── zoxide ────────────────────────────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── direnv ────────────────────────────────────────────────────────────────────
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ── bun ───────────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias vim=nvim
command -v batcat &>/dev/null && alias bat="batcat"
alias zz="z -"

# eza (ls moderno com ícones) — só se instalado
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
fi

# bat (cat com syntax highlight) — --paging=never pra se comportar como cat
command -v bat &>/dev/null && alias cat='bat --paging=never'

# git
alias g='git'
alias lg='lazygit'
