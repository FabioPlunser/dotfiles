# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
eval $(keychain --eval --quiet id_rsa)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DISPLAY=:0
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
export XDG_CONFIG_HOME="$HOME/.config"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$PATH:/opt/nvim-linux64/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/fabio/.bun/_bun" ] && source "/home/fabio/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
eval "$(zoxide init zsh)"

function find_and_cd() {
  local dir
  dir=$(find . -type d 2>/dev/null | fzf --preview 'tree -C {} | head -100') || return
  cd "$dir"
}



bindkey -s ^f "find_and_cd\n"


# Custom widget for FZF history search and execute
fzf_history_execute_widget() {
  local selected_command
  # Store current buffer and cursor position in case of cancellation
  local original_buffer=$BUFFER
  local original_cursor=$CURSOR

  # Use fc to list history (newest first with -r, no numbers with -n)
  # Pipe to fzf.
  # --query "$LBUFFER" pre-populates fzf search with what's already typed to the left of the cursor.
  # --height, --border, --tac are fzf options for appearance and order.
  # --tac shows recent commands at the top (alternative to fc -r)
  selected_command=$(fc -l -n 1 | fzf --height 40% --border --tac --prompt="Execute History: " --query="$LBUFFER")

  if [[ -n "$selected_command" ]]; then
    # If a command was selected (FZF didn't exit with error/ESC)
    BUFFER="$selected_command" # Put selected command into the buffer
    CURSOR=${#BUFFER}          # Move cursor to the end of the selected command
    zle accept-line            # Execute the command (like pressing Enter)
  else
    # If FZF was cancelled (e.g., by pressing ESC), restore the original buffer and cursor
    BUFFER=$original_buffer
    CURSOR=$original_cursor
    # A little nudge to ensure the display updates correctly after restoring
    zle send-invisible
  fi
  # Ensure the prompt and buffer are redrawn correctly
  zle redisplay
}

# Create a new ZLE (Zsh Line Editor) widget from the function
zle -N fzf_history_execute_widget

# Bind CTRL+H to the new widget
# '^H' represents CTRL+H
# WARNING: This will override the default behavior of CTRL+H (often backspace)
bindkey '^H' fzf_history_execute_widget


alias wip='git add . && git commit -m "wip" && git push'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

alias bunw='/mnt/c/Users/f.plunser/.bun/bin/bun.exe'
alias bunxw='/mnt/c/Users/f.plunser/.bun/bin/bunx.exe'
alias cargo='/mnt/c/Users/f.plunser/.cargo/bin/cargo.exe'
alias lg='lazygit'

# opencode
export PATH=/Users/fabioplunser/.opencode/bin:$PATH
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Library/TeX/texbin:$PATH"
