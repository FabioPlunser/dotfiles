#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# OS detection
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            ;;
        Linux)
            OS="linux"
            ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
    log_info "Detected OS: $OS"
}

# Package manager detection for Linux
detect_package_manager() {
    if command_exists apt; then
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt update && sudo apt install -y"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    elif command_exists apk; then
        PACKAGE_MANAGER="apk"
        INSTALL_CMD="sudo apk add"
    else
        log_error "No supported package manager found"
        exit 1
    fi
    log_info "Detected package manager: $PACKAGE_MANAGER"
}

# Install base packages
install_base_packages() {
    log_info "Installing base packages..."
    case $OS in
        macos)
            if ! command_exists brew; then
                log_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
                exit 1
            fi
            brew install git curl zsh tmux neovim
            ;;
        linux)
            $INSTALL_CMD git curl zsh tmux neovim
            ;;
    esac
}

# Install Neovim dependencies
install_neovim_deps() {
    log_info "Installing Neovim dependencies..."

    # Install Rust if not present
    if ! command_exists cargo; then
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        log_info "Rust already installed"
    fi

    # Install nvm and Node.js if not present
    if ! command_exists nvm; then
        log_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
    else
        log_info "nvm already installed"
    fi
}

# Install tmux dependencies
install_tmux_deps() {
    log_info "Installing tmux dependencies..."

    # Install TPM
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        log_info "TPM already installed"
    fi
}

# Install zsh dependencies
install_zsh_deps() {
    log_info "Installing zsh dependencies..."

    # Install oh-my-zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "oh-my-zsh already installed"
    fi

    # Install powerlevel10k theme
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        log_info "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    else
        log_info "powerlevel10k already installed"
    fi

    # Install additional tools
    case $OS in
        macos)
            brew install zoxide fzf keychain
            ;;
        linux)
            $INSTALL_CMD zoxide fzf keychain
            ;;
    esac

    # Install bun if not present
    if ! command_exists bun; then
        log_info "Installing bun..."
        curl -fsSL https://bun.sh/install | bash
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
    else
        log_info "bun already installed"
    fi
}

# Main installation function
main() {
    log_info "Starting package installation for dotfiles setup..."

    detect_os

    if [ "$OS" = "linux" ]; then
        detect_package_manager
    fi

    install_base_packages
    install_neovim_deps
    install_tmux_deps
    install_zsh_deps

    log_info "Package installation completed!"
    log_info "Next steps:"
    log_info "1. Restart your shell or run 'source ~/.zshrc' to apply changes"
    log_info "2. For tmux plugins, open tmux and press prefix + I to install plugins"
    log_info "3. For Neovim, open nvim and run :Lazy to install plugins"
    log_info "4. Configure powerlevel10k by running 'p10k configure'"
}

main "$@"