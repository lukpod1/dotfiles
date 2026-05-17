#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Requerido: $1  (instale com: $2)"; exit 1; }
}

require stow "apt install stow  /  brew install stow"

echo "→ Linkando configuração do vim..."
stow --dir="$DOTFILES" --target="$HOME" --restow vim

echo "→ Linkando configuração do tmux..."
stow --dir="$DOTFILES" --target="$HOME" --restow tmux

DRACULA="$HOME/.tmux/plugins/dracula/scripts"
if [[ -d "$DRACULA" ]]; then
  echo "→ Linkando scripts do Dracula..."
  ln -sf "$DOTFILES/tmux/scripts/claude_usage.sh" "$DRACULA/claude_usage.sh"
  ln -sf "$DOTFILES/tmux/scripts/claude_parse.py"  "$DRACULA/claude_parse.py"
else
  echo "⚠  Plugin Dracula não encontrado em $DRACULA"
  echo "   Instale os plugins do TPM primeiro (prefix + I) e execute este script novamente."
fi

echo "✔ Pronto."
