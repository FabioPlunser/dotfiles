# Shared environment and aliases, sourced by ~/.zshrc (macOS, Linux, WSL2)
# and ~/.bashrc (Git Bash on Windows). Keep this POSIX sh compatible.

# ---------------------------------------------------------------- platform ---
case "$(uname -s)" in
  Darwin) DOTFILES_OS=macos ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then DOTFILES_OS=wsl
    else DOTFILES_OS=linux; fi ;;
  MINGW* | MSYS* | CYGWIN*) DOTFILES_OS=windows ;;
  *) DOTFILES_OS=unknown ;;
esac
export DOTFILES_OS
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Add a directory to PATH only if it exists and is not already there.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}

# --------------------------------------------------------------- homebrew ---
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
  /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$_brew" ]; then eval "$("$_brew" shellenv)"; break; fi
done
unset _brew

# ------------------------------------------------------------------- PATH ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
export PNPM_HOME="$HOME/.local/share/pnpm"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.opencode/bin"

if [ "$DOTFILES_OS" = macos ]; then
  path_prepend /Library/TeX/texbin
  path_prepend /opt/homebrew/opt/ruby/bin
  for _gems in /opt/homebrew/lib/ruby/gems/*/bin; do path_prepend "$_gems"; done
  unset _gems
fi

path_prepend "$HOME/.local/bin"
export PATH

# ---------------------------------------------------------------- general ---
# On native Windows, Neovim reads %LOCALAPPDATA%\nvim; setting XDG_CONFIG_HOME
# there would point it somewhere else.
[ "$DOTFILES_OS" != windows ] && export XDG_CONFIG_HOME="$HOME/.config"

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim VISUAL=nvim
fi

# Node via nvm (git clone in ~/.nvm, or the Homebrew formula)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
elif [ -n "${HOMEBREW_PREFIX:-}" ] && [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
  . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
fi

# ---------------------------------------------------------------- aliases ---
alias wip='git add . && git commit -m "wip" && git push'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias lg='lazygit'
alias personal='cd ~/Nextcloud/personal'
alias uni='cd ~/Nextcloud/Uni/'
alias dot='cd "$DOTFILES"'

if [ "$DOTFILES_OS" = wsl ]; then
  # Windows-side binaries via WSL interop (found on the appended Windows PATH)
  alias bunw='bun.exe'
  alias bunxw='bunx.exe'
  alias cargow='cargo.exe'
  # WSLg normally sets DISPLAY already
  export DISPLAY="${DISPLAY:-:0}"
fi
