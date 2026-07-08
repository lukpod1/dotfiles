#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "→ $1"; }
warn() { echo "⚠  $1"; }

# -----------------------------------------------------------------------------
# 1. Pacotes oficiais via pacman
# -----------------------------------------------------------------------------
log "Instalando pacotes oficiais (pacman)..."
sudo pacman -Syu --needed --noconfirm \
  zsh git vim tmux stow \
  curl wget unzip zip tar make gcc openssh gnupg \
  htop fzf cmatrix go base-devel

# -----------------------------------------------------------------------------
# 2. AUR helper (yay) + pacotes AUR
# -----------------------------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
  log "Instalando yay (AUR helper)..."
  YAY_DIR="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$YAY_DIR"
  (cd "$YAY_DIR" && makepkg -si --noconfirm)
  rm -rf "$YAY_DIR"
else
  log "yay já instalado, pulando."
fi

log "Instalando pacotes AUR/extra (gh, helix, zed)..."
yay -S --needed --noconfirm github-cli helix zed

# opencode e ntn (Notion CLI) não têm pacote no Arch/AUR de forma confiável;
# instalar via script/npm oficial depois que o Node estiver disponível (seção 3/6).

# -----------------------------------------------------------------------------
# 3. Runtimes: nvm, node, bun, pnpm
# -----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  log "Instalando nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

log "Instalando Node 24 via nvm..."
nvm install 24
corepack enable pnpm

if [[ ! -d "$HOME/.bun" ]]; then
  log "Instalando bun..."
  curl -fsSL https://bun.sh/install | bash
else
  log "bun já instalado, pulando."
fi

# -----------------------------------------------------------------------------
# 4. Oh My Zsh + zinit + plugins
# -----------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Instalando Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh já instalado, pulando."
fi

DRACULA_ZSH="$HOME/.oh-my-zsh/custom/themes/dracula"
if [[ ! -d "$DRACULA_ZSH" ]]; then
  log "Instalando tema Dracula para zsh..."
  git clone https://github.com/dracula/zsh.git "$DRACULA_ZSH"
  ln -sf "$DRACULA_ZSH/dracula.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/dracula.zsh-theme"
fi

ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  log "Instalando zinit..."
  mkdir -p "$HOME/.local/share/zinit"
  git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
else
  log "zinit já instalado, pulando."
fi

# -----------------------------------------------------------------------------
# 5. TPM (Tmux Plugin Manager)
# -----------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  log "Clonando TPM..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  warn "Abra o tmux e rode 'prefix + I' para instalar os plugins (dracula, resurrect, continuum, etc)."
else
  log "TPM já instalado, pulando."
fi

# -----------------------------------------------------------------------------
# 6. Claude Code CLI
# -----------------------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  log "Instalando Claude Code CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  log "Claude Code CLI já instalado, pulando."
fi

# -----------------------------------------------------------------------------
# 7. Dotfiles deste repositório (vim, tmux, scripts do Dracula, .wslconfig)
# -----------------------------------------------------------------------------
log "Rodando install.sh para linkar os dotfiles..."
"$DOTFILES/install.sh"

# -----------------------------------------------------------------------------
# 8. Passos manuais (ações sensíveis, não automatizadas)
# -----------------------------------------------------------------------------
cat <<'EOF'

✔ Instalação automática concluída. Passos manuais restantes:

  1. Copie sua chave SSH de assinatura de commits para o novo ambiente:
       ~/.ssh/id_ed25519 (+ .pub)
     e garanta as permissões corretas: chmod 600 ~/.ssh/id_ed25519

  2. Configure o git (se não vier de um dotfile versionado):
       git config --global user.name  "José Lucas"
       git config --global user.email "lukasalvespod1@gmail.com"
       git config --global user.signingkey ~/.ssh/id_ed25519
       git config --global gpg.format ssh
       git config --global commit.gpgsign true
       git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
     e recrie ~/.config/git/allowed_signers com a chave pública correspondente.

  3. No Docker Desktop (Windows): Settings → Resources → WSL Integration →
     habilite a integração com a distro Arch.

  4. Troque o shell padrão para zsh, se desejar:
       chsh -s "$(command -v zsh)"

  5. Reinicie o terminal/tmux e confirme que a status bar Dracula e os
     widgets claude_usage/claude_weekly aparecem corretamente.

EOF
