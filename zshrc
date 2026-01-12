export LANG=en_US.UTF-8

##### PERF #####
setopt NO_BEEP
setopt NO_HUP
setopt INTERACTIVE_COMMENTS

export GPG_TTY="$(tty)"

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

# Vi-mode cursor
function zle-keymap-select {
  [[ $KEYMAP == vicmd ]] && echo -ne '\e[1 q' || echo -ne '\e[5 q'
}
zle -N zle-keymap-select
echo -ne '\e[5 q'

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

##### GIT PROMPT #####
autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}(%b|%a)%f'

precmd() { vcs_info }

git_dirty() {
  git rev-parse --is-inside-work-tree &>/dev/null &&
  ! git diff --quiet && echo '*'
}

PROMPT='%F{green}%n@%m%f %F{blue}%~%f ${vcs_info_msg_0_}$(git_dirty)
%# '
export REVIEW_BASE=staging

##### FZF #####
eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

### Aliases
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

### Functions
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh

##### Plugins #####
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
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
