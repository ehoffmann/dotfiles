ZSH=$HOME/.oh-my-zsh

ZSH_THEME="ehoffmann"

# zsh builtin
autoload -U zmv

# Vi mode
set -o vi
export EDITOR=vim
export VISUAL=vim
bindkey -v

# Not to be disturbed by Ctrl-S Ctrl-Q in terminals
stty -ixon

# -----------------------------------------------------------------------------
# Config alias
# -----------------------------------------------------------------------------
alias zshconf="vim ~/.zshrc"
alias vimconf="vim ~/.vimrc"
alias tmuxconf="vim ~/.tmux.conf"

# -----------------------------------------------------------------------------
# Rails
# -----------------------------------------------------------------------------
alias be='bundle exec'
alias brake='bundle exec rake'
alias rubytag='ctags -R --languages=ruby --exclude=.git --exclude=log .'

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias gloo='git --no-pager log --oneline --decorate --color | head '
alias gla="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glb="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
# Clean branches already merged on staging
alias git-clean-branch='git fetch; git branch --merged staging | egrep -v "(^\*|master|staging)" | xargs git branch -d'
export REVIEW_BASE=staging

# -----------------------------------------------------------------------------
# TMUX
# -----------------------------------------------------------------------------
alias tmxu='tmux'
alias mux=tmuxinator

# -----------------------------------------------------------------------------
# fzf
# -----------------------------------------------------------------------------
# Default fzf search for vim
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

# -----------------------------------------------------------------------------
# Misc
# -----------------------------------------------------------------------------
alias bell="printf '\aBELL\!\n'"

kim() {
  read -r host port < ~/.kim
  ssh $host -p $port
}

# -----------------------------------------------------------------------------
# k8s deploy & console
# -----------------------------------------------------------------------------

_k8s() {
  host=$(cat ~/.prod-k8s)
  ssh -t $host "kubectl -n $1 get pods | grep -v ImagePullBackOff | grep $2 | awk '{print\$1}' | xargs -to -i{} kubectl -n $1 exec -it {} $3"
}

# Launch a command into a themed terminal
g-term() { # $profile $command
  gnome-terminal --window-with-profile="$1" -- zsh -ic "$2"
}

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dco='docker compose'
alias dcr='docker compose stop && docker compose up'
alias drm='docker rm $(docker ps -a -q)'
alias dsc='docker stop $(docker ps -q)'

# Remove untaged images
drmi() {
  echo "drmi is deprecated, use 'docker system prune' instead"
}

# Remove all docker containers and images
drmall() {
  echo "drmall is deprecated, use 'docker system prune -a' instead"
}

# -----------------------------------------------------------------------------
# linters
# -----------------------------------------------------------------------------

# Lint current diff or from $1 commit earlier
rubo() {
  if [ -n "$1" ]
  then
    git diff --name-status HEAD~"$1" HEAD | grep '^[A,M].*\.rb$' | cut -f2 | xargs -r rubocop --rails
  else
    git diff --name-only --diff-filter=d | grep '.rb$' | xargs -r rubocop --rails
  fi
}

# Lint cached
rubs() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop
}

rubsa() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop --auto-correct
}

# -----------------------------------------------------------------------------
# ssh and forward auto
# -----------------------------------------------------------------------------
ssha() {
  eval `ssh-agent -s` >/dev/null
  ssh-add &>/dev/null
}
ssha;

# -----------------------------------------------------------------------------
# zsh plugins
# -----------------------------------------------------------------------------
plugins=(git
  rails
  web-search
  vi-mode
  history-substring-search
)

# -----------------------------------------------------------------------------
# Project related
# -----------------------------------------------------------------------------
alias wk="mux work"
alias prj="mux prj"
alias code="mux code"
alias dot="mux dotfiles"
alias leet="mux leet"
alias euler="mux euler"
alias srv="mux server"
alias retake="sudo chown -R manu:manu ."
alias mto='curl -4 http://wttr.in/Marseille'
alias -g rgi='| rg -i'
alias -g gpi='| rg -i'
# remove vim swap file, with confirmation
alias rmswp="find . -name '*.swp' -exec rm -i '{}' \;"

# -----------------------------------------------------------------------------
# oh-my-zsh
# -----------------------------------------------------------------------------
source $ZSH/oh-my-zsh.sh

# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
export PATH=~/bin:/opt/Telegram:$PATH
export PATH="$PATH:/usr/games:/usr/local/games"

# -----------------------------------------------------------------------------
# MISC
# -----------------------------------------------------------------------------
export EDITOR=vim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# cycle through arg history
bindkey '^O' insert-last-word

# bind k and j for VI mode (history-substring-search plugin)
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Delay after <ESC> press in milisec (defaul = 4)
export KEYTIMEOUT=10

### chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh # Auto switch, per project: echo "ruby-2.7.6" > ~/.ruby-version

# Installed with `sudo ruby-build 2.7.6 /opt/rubies/ruby-2.7.6`
# chruby 2.7.6

# Installed with `sudo ruby-build 3.0.4 /opt/rubies/ruby-3.0.4`
# chruby 3.0.4

# Installed with `sudo ruby-build 3.2.0 /opt/rubies/ruby-3.2.0`
# List available builds: `ruby-build --definitions`
# List locales version : `chruby`
# chruby 3.2.0
# chruby 3.3.6
chruby 3.4.8

install_ruby() {
  # Usage: install_ruby <version>
  # Example: install_ruby 3.3.0

  if [ -z "$1" ]; then
    echo "Error: Ruby version not specified."
    echo "Usage: install_ruby <version>"
    return 1
  fi

  local version="$1"
  # Extract the major and minor version (e.g., 3.3 from 3.3.0)
  local major_minor_version="${version%.*}"

  # Install dependencies (uncomment if not already installed)
  # sudo apt install -y build-essential bison zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libffi-dev

  wget "https://cache.ruby-lang.org/pub/ruby/${major_minor_version}/ruby-${version}.tar.xz"
  tar -xJvf "ruby-${version}.tar.xz"
  rm "ruby-${version}.tar.xz"
  cd "ruby-${version}"
  ./configure --prefix="/opt/rubies/ruby-${version}"
  make
  sudo make install
  cd ..
  sudo rm -rf "ruby-${version}"
}
###

# tmuxinator completion/alias
source ~/.bin/tmuxinator.zsh

# Zsh syntax hi
source ~/code/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Rust
source "$HOME/.cargo/env"

# GPG agent
GPG_TTY=`tty`
export GPG_TTY

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source ~/.localrc
