export LANG=en_US.UTF-8
if [ -d "$HOME/bin" ] ; then
  PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
  PATH="$HOME/.local/bin:$PATH"
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
bindkey -v
set -o vi
export EDITOR=vim
export VISUAL=vim
export KEYTIMEOUT=1 # Delay after <ESC> press in milisec (defaul = 4)

##### History #####
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
# setopt HIST_BEEP                 # Beep when accessing nonexistent history.


##### COMPLETION #####
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

##### FZF #####
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

### Aliases
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

### Prompt
[[ -f ~/.zsh/prompt.zsh ]] && source ~/.zsh/prompt.zsh

### Functions
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh

##### Plugins #####
# source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh # Auto switch, per project: echo "ruby-2.7.6" > ~/.ruby-version

# Autosuggestions
bindkey '^l' autosuggest-accept
bindkey -M viins '^l' autosuggest-accept

##### chruby #####
# Check avalable versions:
# ls /opt/rubies'
# install_ruby 3.4.8
chruby 4.0.0
