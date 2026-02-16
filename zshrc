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

##### Vi mode #####
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -v
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
export EDITOR=vim
export VISUAL=vim
export KEYTIMEOUT=1 # Delay after <ESC> press in milisec (defaul = 4)
bindkey '^X^E' edit-command-line
bindkey -M vicmd 'v' edit-command-line

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

# Per-tmux-session history (shared among panes/windows of same tmux session)
if [[ -n "$TMUX" ]]; then
  local _tmux_sess
  _tmux_sess="$(tmux display-message -p '#S' 2>/dev/null)"
  HISTFILE="$HOME/.tmux-${_tmux_sess}.zsh_history"
else
  HISTFILE="$HOME/.zsh_history"
fi

##### COMPLETION #####
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

##### FZF #####
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='rg --files'
export FZF_DEFAULT_OPTS='--height 40% --tmux top,80%'
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

##### Plugins #####
[[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

# Autosuggestions
bindkey '^y' autosuggest-accept
bindkey -M viins '^y' autosuggest-accept

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
