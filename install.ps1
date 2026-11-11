# One-command setup for native Windows. Run in PowerShell (no admin needed):
#
#   iex (irm 'https://raw.githubusercontent.com/FabioPlunser/dotfiles/main/install.ps1')
#
# Installs Git + chezmoi with winget, clones the repo to ~\dotfiles and applies it:
# Git Bash config, Neovim (junction at %LOCALAPPDATA%\nvim), Zed, git, and the
# winget packages listed in home/.chezmoidata/packages.yaml.
# For WSL2, run install.sh inside the Linux distro instead.
$ErrorActionPreference = 'Stop'

$repo = if ($env:DOTFILES_REPO) { $env:DOTFILES_REPO } else { 'https://github.com/FabioPlunser/dotfiles.git' }
$dotfiles = if ($env:DOTFILES) { $env:DOTFILES } else { Join-Path $HOME 'dotfiles' }

function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget not found. Install "App Installer" from the Microsoft Store and re-run.'
}

foreach ($pkg in @(@{ cmd = 'git'; id = 'Git.Git' }, @{ cmd = 'chezmoi'; id = 'twpayne.chezmoi' })) {
  if (-not (Get-Command $pkg.cmd -ErrorAction SilentlyContinue)) {
    Write-Host "==> Installing $($pkg.id)"
    winget install --id $pkg.id --exact --silent --accept-source-agreements --accept-package-agreements
    Refresh-Path
  }
}

# Non-interactive use (CI, agents): set DOTFILES_GIT_NAME and DOTFILES_GIT_EMAIL
# to skip the prompts, and DOTFILES_NONINTERACTIVE=1 to never wait for input.
$initArgs = @('init', '--source', $dotfiles, '--apply')
if ($env:DOTFILES_GIT_NAME -and $env:DOTFILES_GIT_EMAIL) {
  $initArgs += @('--promptString', "Git user name=$($env:DOTFILES_GIT_NAME),Git email address=$($env:DOTFILES_GIT_EMAIL)")
}
if ($env:DOTFILES_NONINTERACTIVE -eq '1') { $initArgs += @('--no-tty', '--force') }

if (Test-Path (Join-Path $dotfiles '.git')) {
  Write-Host "==> Using existing repo at $dotfiles"
  & chezmoi @initArgs
} else {
  Write-Host "==> Cloning $repo into $dotfiles"
  & chezmoi @initArgs $repo
}

Write-Host ''
Write-Host 'Done. Open Git Bash (or a new terminal) to pick up the config.'
