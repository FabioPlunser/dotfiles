#!/usr/bin/env bash
# One-command setup for macOS, Linux and WSL2 (and Git Bash on Windows, which
# hands off to install.ps1):
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.sh)"
#
# or, from an existing clone:  ~/dotfiles/install.sh
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/FabioPlunser/dotfiles.git}"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    echo "==> Git Bash detected, running the Windows installer (install.ps1)"
    if [ -f "$DOTFILES/install.ps1" ]; then
      exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$DOTFILES/install.ps1")"
    else
      exec powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "iex (irm 'https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.ps1')"
    fi
    ;;
esac

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "==> Installing chezmoi into ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$DOTFILES/.git" ]; then
  echo "==> Using existing repo at $DOTFILES"
  chezmoi init --source "$DOTFILES" --apply
else
  echo "==> Cloning $REPO into $DOTFILES"
  chezmoi init --source "$DOTFILES" --apply "$REPO"
fi

echo
echo "Done. Open a new terminal (or run: exec zsh)."
