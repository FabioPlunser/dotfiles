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

# Non-interactive use (CI, agents): set DOTFILES_GIT_NAME and DOTFILES_GIT_EMAIL
# to skip the prompts, and DOTFILES_NONINTERACTIVE=1 to never wait for input.
init_args=(--source "$DOTFILES" --apply)
if [ -n "${DOTFILES_GIT_NAME:-}" ] && [ -n "${DOTFILES_GIT_EMAIL:-}" ]; then
  init_args+=(--promptString "Git user name=$DOTFILES_GIT_NAME,Git email address=$DOTFILES_GIT_EMAIL")
fi
if [ "${DOTFILES_NONINTERACTIVE:-0}" = 1 ]; then
  init_args+=(--no-tty --force)
fi

if [ -d "$DOTFILES/.git" ]; then
  echo "==> Using existing repo at $DOTFILES"
  chezmoi init "${init_args[@]}"
else
  echo "==> Cloning $REPO into $DOTFILES"
  chezmoi init "${init_args[@]}" "$REPO"
fi

echo
echo "Done. Open a new terminal (or run: exec zsh)."
