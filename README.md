# dotfiles

Configs pessoais: Neovim, tmux, zsh, git, ghostty, Claude Code e alguns scripts.
Cobre macOS, Linux e WSL (Windows nativo não é alvo — sem WSL, tmux não roda).

## Instalar

```bash
git clone https://github.com/omatheusmol/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
```

Pré-requisito único: `git` já precisa existir antes do clone (`sudo apt install -y git` no Linux/WSL se não vier por padrão).

O script instala pacotes (brew no macOS, apt no Linux/WSL), Neovim, tmux + TPM,
Go, Node (nvm), Rust, Claude Code CLI, Piper TTS + modelos de voz, e cria os
symlinks de todas as configs abaixo. É idempotente — rodar de novo não reinstala
nem sobrescreve o que já está certo.

## Desinstalar

```bash
bash ~/.dotfiles/uninstall.sh
```

Remove os symlinks e restaura qualquer config que já existia antes de rodar o
`install.sh` (arquivos reais são movidos para `<arquivo>.pre-dotfiles` no
momento do link, e voltam pro lugar aqui). Pacotes instalados via
brew/apt/nvm/rustup/TPM/Piper **não** são removidos — são aditivos, não
sobrescrevem nada de quem já usava a máquina.

Útil para usar a máquina de outra pessoa temporariamente sem deixar rastro.

## Estrutura

| Pasta | O quê |
|---|---|
| `nvim/` | Config do Neovim (lazy.nvim) |
| `tmux/` | `.tmux.conf` + config do `tmux-which-key` |
| `zsh/` | `.zshrc` |
| `git/` | `.gitconfig` |
| `ghostty/` | Config do terminal (macOS) |
| `claude/` | Config global do Claude Code: `settings.json`, `commands/`, `hooks/` |
| `skhd/` | Atalhos globais (macOS only): screenshot/arquivo → caminho no clipboard |
| `bin/` | Scripts (`speak.sh`, `mpvctl`, `tmux-sessionizer`, etc), symlinkados pra `~/.local/bin` |
| `Brewfile` | Pacotes do macOS |

## O que funciona onde

| | macOS | Linux | WSL |
|---|---|---|---|
| Neovim | ✅ | ✅ | ✅ |
| tmux (which-key, painel, controles) | ✅ | ✅ | ✅ |
| Piper TTS + mpv (voz do `/say` e do `R` no copy-mode) | ✅ | ✅ | ✅ (áudio pode exigir setup extra do WSL) |
| Claude Code (hooks, `/say`, `/save-memory`) | ✅ | ✅ | ✅ |
| `skhd` + screenshot/clipboard | ✅ | ❌ | ❌ |
