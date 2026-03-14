# Summary:
# - vi mode enabled, with fast ESC
# - Ctrl-A / Ctrl-E: jump to start / end of line in insert mode
# - Alt-.: insert last word from previous command
# - `v` in normal mode: edit current command in vim
# - Alt-s: prepend `sudo` to current command
# - `y` / `Y` in normal mode: yank to system clipboard
# - Ctrl-y: accept autosuggestion
# - Up / Down or `k` / `j`: history substring search
# - fzf enabled for file/dir picking with previews
# - lazy-load nvm on first `node` / `npm` / `npx` / `nvm`

export LANG=en_US.UTF-8
if [ -d "$HOME/bin" ] ; then
  PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
  PATH="$HOME/.local/bin:$PATH"
fi
if [ -d "$HOME/.cargo/bin" ] ; then
  PATH="$HOME/.cargo/bin:$PATH"
fi
if [ -d "$HOME/code/tools/bin" ] ; then
  PATH="$HOME/code/tools/bin:$PATH"
fi

# Ignore the XOFF/XON characters (typically Ctrl-S for XOFF to pause output, Ctrl-Q for XON to resume)
stty -ixon

export GPG_TTY="$(tty)"
export REVIEW_BASE=staging

##### PERF #####
setopt NO_BEEP
setopt NO_HUP
setopt INTERACTIVE_COMMENTS

# Avoid slow compinit on every shell
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Vi mode
export EDITOR=vim
export VISUAL=vim
export KEYTIMEOUT=1 # Delay after <ESC> press in milisec (defaul = 4)
bindkey -v

# Auto-suggest
if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^y' autosuggest-accept
  bindkey -M viins '^y' autosuggest-accept
fi

# Syntax highlight
[[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History substring match with arrow up/down
if [[ -f ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
  bindkey "$key[Up]" history-substring-search-up
  bindkey "$key[Down]" history-substring-search-down
fi

# Restore some useful bindings
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^[.' insert-last-word

# Edit command line in vim with v
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Insert sudo before the command
sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history
  BUFFER="sudo $BUFFER"
  zle end-of-line
}
zle -N sudo-command-line
bindkey '^[s' sudo-command-line

# Yank to clipboard
function vi-yank-xclip {
  zle vi-yank
  print -rn -- "$CUTBUFFER" | xclip -selection clipboard
}
zle -N vi-yank-xclip

bindkey -M vicmd 'y' vi-yank-xclip
bindkey -M vicmd 'Y' vi-yank-xclip

##### History #####
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
unsetopt SHARE_HISTORY

# Hygiene options
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

##### COMPLETION #####
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

##### FZF #####
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='rg --files'
if [[ -n "$TMUX_IN_POPUP" ]]; then
  export FZF_DEFAULT_OPTS='--height 40%'
else
  export FZF_DEFAULT_OPTS='--height 40% --tmux top,99%'
fi
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

### Aliases
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

### Prompt
[[ -f ~/.zsh/prompt.zsh ]] && source ~/.zsh/prompt.zsh

### Functions
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh

# Ruby
if [ -d /usr/local/share/chruby ] ; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh # Auto switch, per project: echo "ruby-2.7.6" > ~/.ruby-version
  # Check available local versions:
  # ls /opt/rubies'
  # Check available remote version
  # list_ruby_version
  # build and install a new version
  # build_ruby x.x.x
  chruby 4.0.1
fi

# Node, lazy
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm "$@"
}
node() { nvm; node "$@"; }
npm()  { nvm; npm "$@"; }
npx()  { nvm; npx "$@"; }
