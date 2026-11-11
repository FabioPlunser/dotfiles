# AGENTS.md

How AI coding agents install, verify and change these dotfiles. Read `README.md` for the human overview.

## What this repo is

- Dotfiles for **macOS, Linux, WSL2 and native Windows (Git Bash)**, managed by [chezmoi](https://chezmoi.io).
- The repo is cloned to `~/dotfiles`; `.chezmoiroot` makes `home/` the chezmoi source directory.
- `nvim/` at the repo root is the Neovim config. It is linked, not copied: a symlink at `~/.config/nvim` on unix,
  a junction at `%LOCALAPPDATA%\nvim` on Windows.
- **The repo is public.** Never commit email addresses, tokens, SSH keys, `~/.config/gh/hosts.yml` or other secrets.
  Git name/email come from chezmoi prompt data stored in `~/.config/chezmoi/chezmoi.toml`, outside the repo.

## Install non-interactively

The installer normally prompts for the git name/email, the sudo password (Linux) and `chsh`. As an agent, set these
environment variables so nothing waits for input:

| Variable | Effect |
| --- | --- |
| `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL` | Answer chezmoi's two prompts. Ask the user for the values, or read them from `git config --global user.name/user.email` on the machine. Don't invent them, and never write them into the repo. |
| `DOTFILES_NONINTERACTIVE=1` | Pass `--no-tty --force` to chezmoi (overwrites existing targets without asking), use `sudo -n` on Linux (fails instead of prompting), and skip `chsh`. |
| `DOTFILES` | Clone location (default `~/dotfiles`). |
| `HOMEBREW_NO_AUTO_UPDATE=1` | Optional: faster Homebrew runs. |

### macOS / Linux / WSL2

```sh
DOTFILES_GIT_NAME="..." DOTFILES_GIT_EMAIL="..." DOTFILES_NONINTERACTIVE=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.sh)"
# or, if ~/dotfiles is already cloned:
DOTFILES_GIT_NAME="..." DOTFILES_GIT_EMAIL="..." DOTFILES_NONINTERACTIVE=1 ~/dotfiles/install.sh
```

On Linux/WSL2 the first step installs system packages with `sudo`. With `DOTFILES_NONINTERACTIVE=1` this needs
passwordless sudo (or root); otherwise it prints an error and the run continues without them. If sudo needs a password,
ask the user to provide it through a secure prompt or have them run the installer themselves. Never put the password
on the command line.

### Native Windows (PowerShell, no admin)

```powershell
$env:DOTFILES_GIT_NAME = '...'; $env:DOTFILES_GIT_EMAIL = '...'; $env:DOTFILES_NONINTERACTIVE = '1'
iex (irm 'https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.ps1')
```

From Git Bash, `install.sh` detects Windows and hands off to `install.ps1` (env vars are passed through).
Packages come from winget, which must exist (the "App Installer" from the Microsoft Store).
For WSL2, run the Linux command **inside** the distro as well; it is a separate environment.

## What the install does (in order)

1. Installs chezmoi (to `~/.local/bin` on unix, winget on Windows) and clones the repo to `~/dotfiles`.
2. Renders `home/.chezmoi.toml.tmpl` into `~/.config/chezmoi/chezmoi.toml` (`sourceDir`, `mode = "symlink"` on unix, name/email).
3. `run_onchange_before_10-install-packages-<os>`: packages from `home/.chezmoidata/packages.yaml`.
4. Applies files and clones externals (`home/.chezmoiexternal.toml.tmpl`: oh-my-zsh, powerlevel10k, zsh plugins, TPM).
5. After-scripts: rustup / nvm + Node LTS / Bun (unix), login shell → zsh, tmux plugins + `nvim "+Lazy! restore"`,
   the Windows nvim junction, and the Zebar Swift helper builds (macOS).

Everything is idempotent; re-running `chezmoi apply` is safe. Package lines that fail print `WARN:` and the run continues,
so **read the output for `WARN`** rather than relying on the exit code alone.

## Verify

```sh
chezmoi doctor                 # chezmoi itself is healthy
chezmoi status                 # empty output = everything applied
ls -la ~/.zshrc ~/.config/nvim # unix: symlinks into ~/dotfiles
zsh -i -c 'echo $DOTFILES_OS; command -v nvim fzf zoxide rg lazygit gh'
nvim --headless "+checkhealth" +qa
```

On Windows: `chezmoi status`, `Get-Item $env:LOCALAPPDATA\nvim` (`LinkType` = `Junction`), then open Git Bash and run
`echo $DOTFILES_OS` (expected: `windows`).

## Making changes

- **Edit sources in `~/dotfiles/home`**, not rendered copies. File names use chezmoi prefixes: `dot_` → `.`,
  `executable_`, `symlink_`, `.tmpl` = Go template, `run_once_`/`run_onchange_` = scripts. See https://chezmoi.io/reference/.
- On unix, plain files are symlinks into the repo, so editing `~/.zshrc` edits `home/dot_zshrc`. Templates
  (`*.tmpl`, e.g. `.gitconfig`) are rendered copies; edit the template and run `chezmoi apply`.
- **Add a package**: edit `home/.chezmoidata/packages.yaml` (`brew`, `brew_darwin`, `casks_darwin`,
  `linux_prereqs`, `winget`), then run `chezmoi apply`. The install script re-runs because its hash comment changes.
- **Add a config file**: `chezmoi add ~/.config/foo/bar` (or `--template` if it needs per-OS values), then restrict
  it per OS in `home/.chezmoiignore` if it only applies to some platforms.
- **Per-OS logic**: runtime checks go in `home/dot_config/shell/common.sh` (`$DOTFILES_OS` = `macos|linux|wsl|windows`).
  File-level checks use templates with `.chezmoi.os` (`darwin|linux|windows`).
- **Machine-specific, untracked settings** go in `~/.zshrc.local`, `~/.bashrc.local` and `~/.gitconfig.local`.
- Shared shell code must stay POSIX `sh` (it is sourced by both zsh and Git Bash).
- Scripts in `home/.chezmoiscripts/` wrap their whole body in `{{ if eq .chezmoi.os "..." }}`; a script that renders
  empty is skipped on that OS. Keep installers from editing rc files (e.g. `--no-modify-path`, `PROFILE=/dev/null`).

Before committing, check the rendered output on each OS and for leaked secrets:

```sh
chezmoi diff
chezmoi execute-template < home/<file>.tmpl
bash -n <rendered script>; zsh -n home/dot_zshrc; sh -n home/dot_config/shell/common.sh
git grep -nE "gho_|ghp_|BEGIN .*PRIVATE|@outlook|@gmail" -- . ':!nvim'
```

## Git

- Remote: `git@github.com:FabioPlunser/dotfiles.git`. If SSH auth fails in a non-interactive session (passphrase-protected
  key), push over HTTPS with the GitHub CLI credential helper:
  `git -c credential.helper= -c credential.helper='!gh auth git-credential' push https://github.com/FabioPlunser/dotfiles.git <branch>`
- Work on a branch and open a PR; don't push straight to `main` unless the user asks.
