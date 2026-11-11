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

die() { echo "ERROR: $*" >&2; exit 1; }
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }
as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"
  elif [ "${DOTFILES_NONINTERACTIVE:-0}" = 1 ]; then sudo -n "$@"
  else sudo "$@"; fi
}

# ------------------------------------------------- corporate TLS proxies ---
# Networks that inspect HTTPS (e.g. company proxies) re-sign traffic with their
# own root CA. Windows trusts it via group policy, WSL does not, so every
# download fails with "self-signed certificate in certificate chain" (curl 60).
# On WSL we copy the Windows trusted root CAs into the Linux trust store.

tls_broken() {
  local url rc
  for url in https://get.chezmoi.io https://github.com https://objects.githubusercontent.com; do
    rc=0; curl -sS -o /dev/null --max-time 20 "$url" 2>/dev/null || rc=$?
    [ "$rc" -eq 60 ] && return 0 # 60 = peer certificate cannot be authenticated
  done
  return 1
}

import_windows_root_cas() {
  local ps store_dir refresh tmp n=0 thumb b64
  ps=$(command -v powershell.exe || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)
  [ -x "$ps" ] || die "powershell.exe not reachable from WSL (is Windows interop disabled?)"

  if command -v update-ca-certificates >/dev/null 2>&1; then # Debian/Ubuntu/Arch
    store_dir=/usr/local/share/ca-certificates; refresh=(update-ca-certificates)
  elif command -v update-ca-trust >/dev/null 2>&1; then # Fedora/RHEL
    store_dir=/etc/pki/ca-trust/source/anchors; refresh=(update-ca-trust extract)
  else
    die "no update-ca-certificates/update-ca-trust; install the ca-certificates package first"
  fi

  echo "==> HTTPS is intercepted (corporate proxy?). Importing Windows trusted root CAs into WSL"
  tmp=$(mktemp -d)
  # One "thumbprint base64" line per valid root certificate from the Windows stores.
  while read -r thumb b64; do
    [ -n "${b64:-}" ] || continue
    { echo "-----BEGIN CERTIFICATE-----"; echo "$b64" | fold -w 64; echo "-----END CERTIFICATE-----"; } \
      >"$tmp/windows-root-$thumb.crt"
    n=$((n + 1))
  done < <(cd /mnt/c 2>/dev/null; "$ps" -NoProfile -NonInteractive -Command \
    'Get-ChildItem Cert:\LocalMachine\Root, Cert:\CurrentUser\Root |
       Where-Object { $_.NotAfter -gt (Get-Date) } |
       ForEach-Object { $_.Thumbprint + " " + [Convert]::ToBase64String($_.RawData) }' | tr -d '\r')
  [ "$n" -gt 0 ] || die "could not read any certificates from the Windows certificate store"

  as_root mkdir -p "$store_dir"
  as_root cp "$tmp"/windows-root-*.crt "$store_dir"/
  as_root "${refresh[@]}" >/dev/null
  rm -rf "$tmp"
  echo "    imported $n certificates into $store_dir"
}

if tls_broken; then
  if is_wsl; then
    import_windows_root_cas
    tls_broken && die "HTTPS still fails after importing the Windows CAs. Ask IT for the proxy root CA (.crt), copy it to /usr/local/share/ca-certificates/ and run: sudo update-ca-certificates"
  else
    die "HTTPS certificate verification fails (TLS-inspecting proxy?). Add your organisation's root CA to the system trust store and re-run."
  fi
fi

# Point tools that ship their own CA bundle (Homebrew's OpenSSL, Python, Node,
# uv, ...) at the system store, so an imported corporate CA is trusted there too.
# ~/.config/shell/common.sh does the same for interactive shells.
for bundle in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
  if [ "$(uname -s)" = Linux ] && [ -f "$bundle" ]; then
    export SSL_CERT_FILE="$bundle" NODE_EXTRA_CA_CERTS="$bundle" REQUESTS_CA_BUNDLE="$bundle"
    break
  fi
done

# ---------------------------------------------------------------- chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "==> Installing chezmoi into ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  installer=$(curl -fsSL https://get.chezmoi.io) || die "could not download the chezmoi installer"
  sh -c "$installer" -- -b "$HOME/.local/bin" || die "chezmoi installation failed"
  export PATH="$HOME/.local/bin:$PATH"
  command -v chezmoi >/dev/null 2>&1 || die "chezmoi not found after installation"
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
