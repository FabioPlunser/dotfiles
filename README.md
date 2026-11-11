# dotfiles

zsh, Neovim, tmux, git, Ghostty, Zed and GlazeWM/Zebar configs for **macOS, Linux, WSL2 and native Windows (Git Bash)**,
managed with [chezmoi](https://chezmoi.io).

## Install (one command)

| Where | Command |
| --- | --- |
| macOS / Linux / WSL2 | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.sh)"` |
| Windows (PowerShell) | `iex (irm 'https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.ps1')` |
| Windows (Git Bash) | same as macOS/Linux; it hands off to `install.ps1` |

On Windows, run it natively **and** inside WSL2. They're separate environments.

The installer:

1. installs chezmoi, clones this repo to `~/dotfiles`, and asks once for your git name/email
   (stored locally in `~/.config/chezmoi/chezmoi.toml`, never committed);
2. installs packages from [`home/.chezmoidata/packages.yaml`](home/.chezmoidata/packages.yaml):
   - **macOS**: Homebrew formulae + casks
   - **Linux/WSL2**: build tools + zsh from apt/pacman/dnf, then the same formulae via Homebrew on Linux
   - **Windows**: winget
3. links the configs into `$HOME`, clones oh-my-zsh, powerlevel10k, the zsh plugins and TPM,
   installs rustup / nvm + Node LTS / Bun, sets zsh as the login shell, and restores
   Neovim + tmux plugins.

Re-running is safe; everything is idempotent.

## Layout

```
install.sh / install.ps1      bootstrap
nvim/                         Neovim config (symlinked to ~/.config/nvim, junction on Windows)
home/                         chezmoi source dir (.chezmoiroot) -> mapped onto $HOME
  dot_zshrc, dot_p10k.zsh     zsh (macOS/Linux/WSL)
  dot_bashrc                  Git Bash (Windows)
  dot_config/shell/common.sh  env, PATH and aliases shared by zsh and bash
  dot_tmux.conf, dot_gitconfig.tmpl, dot_config/{ghostty,zed,gh,git}
  dot_glzr/, Library/         GlazeWM + Zebar + LaunchAgents (macOS only)
  AppData/Roaming/Zed         Zed on Windows (includes dot_config/zed)
  .chezmoidata/packages.yaml  package lists per OS
  .chezmoiscripts/            install scripts (run per OS)
  .chezmoiexternal.toml.tmpl  oh-my-zsh, p10k, zsh plugins, tpm
  .chezmoiignore              which files apply on which OS
```

## Daily use

On macOS/Linux chezmoi runs in **symlink mode**: `~/.zshrc`, `~/.tmux.conf`, `~/.config/nvim`, etc. point
straight into `~/dotfiles`, so edit them anywhere and commit from `~/dotfiles`.
Templates (`*.tmpl`, e.g. `.gitconfig`) are rendered copies: edit them in `~/dotfiles/home` and run `chezmoi apply`.
On Windows everything except `nvim` is copied, so use `chezmoi edit <file>` or `chezmoi re-add`.

```sh
chezmoi apply        # apply repo -> $HOME (also re-runs install scripts if packages.yaml changed)
chezmoi diff         # preview
chezmoi update       # git pull + apply
chezmoi add ~/.foo   # start tracking a new file
```

Machine-specific, untracked overrides: `~/.zshrc.local`, `~/.bashrc.local`, `~/.gitconfig.local`.

Adding a package: put it in `home/.chezmoidata/packages.yaml` and run `chezmoi apply`.

## Notes

- **Corporate networks / TLS inspection (WSL):** if HTTPS fails with `self-signed certificate in certificate chain`,
  `install.sh` copies the Windows trusted root CAs into the WSL trust store (asks for sudo) and points
  Homebrew/Python/Node/uv at the system CA bundle. Native Windows git uses the Windows store (`http.sslBackend=schannel`).
- GlazeWM/Zebar apps themselves aren't installed (the config expects the dev builds in `~/Applications`).
  On a fresh Mac, load the agents once with
  `launchctl load ~/Library/LaunchAgents/io.glzr.zebar-wake.plist ~/Library/LaunchAgents/io.glzr.glazewm-login.plist`.
- Set your terminal font to a Nerd Font (Hack on macOS, JetBrainsMono Nerd Font on Windows) for powerlevel10k.
