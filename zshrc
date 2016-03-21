ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="granutark"

# zsh builtin
autoload -U zmv

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

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias gloo='git --no-pager log --oneline --decorate --color | head '
alias gla="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glb="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"

# -----------------------------------------------------------------------------
# Vagrant
# -----------------------------------------------------------------------------
alias vagrash='vagrant up && vagrant ssh'

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dco='docker-compose'
alias drm='docker rm $(docker ps -a -q)'

de() {
  docker exec -ti $1 bash
}

drmi() {
  docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
}

dcr() {
  docker-compose run --rm web $@
}

dcba() {
  docker-compose run --rm web bash
}

dcguard() {
  docker-compose run --rm web bundle exec guard
}

dcguard_xfvb() {
  docker rm -f guard
  docker-compose run -d --rm --name guard web tail -f /dev/null
  docker exec -d guard sh -c 'Xvfb :99 -ac &'
  docker exec -ti guard sh -c 'export DISPLAY=:99; bundle exec guard'
}

dcmigrate() {
  docker-compose run --rm web bundle exec rake db:migrate
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:migrate
}

dcdbreset_test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:drop db:create db:schema:load
}

dcdbreset_dev() {
  docker-compose run --rm web bundle exec rake db:drop db:create db:schema:load
}

dcdb_load_tco_dev() {
  docker-compose start mysql
  container=$(docker-compose ps mysql | grep Up | awk  '{print $1}')
  echo $container
  echo "clear database"
  docker exec -ti $container mysql -uroot -pfoo -e 'drop database tco_development; create database tco_development'
  echo "loading dump"
  docker exec -i $container mysql tco_development -uroot -pfoo < $1
  echo "running migrations"
  docker-compose run --rm web bundle exec rake db:migrate
}

dcbe() {
  docker-compose run --rm web bundle exec $@
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
plugins=(git npm vagrant rails vi-mode history-substring-search)

# -----------------------------------------------------------------------------
# OSX specific
# -----------------------------------------------------------------------------
case $OSTYPE in
  darwin*)
    plugins+=(osx brew)

    # EC2 stuffs
    export EC2_HOME=~/.ec2
    export PATH=$PATH:$EC2_HOME/bin
    export EC2_PRIVATE_KEY=`ls $EC2_HOME/pk-*.pem`
    export EC2_CERT=`ls $EC2_HOME/cert-*.pem`
    export EC2_URL=https://ec2.eu-west-1.amazonaws.com

    # Java
    export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home/

    # Not to be disturbed by Ctrl-S Ctrl-Q in terminals
    stty -ixon

    # Docker stuffs
    eval "$(docker-machine env default)"
    alias dip='docker-machine ip default'

    dms() {
      docker-machine start default && zsh
    }
    ;;
esac

# -----------------------------------------------------------------------------
# Misc
# -----------------------------------------------------------------------------
source $ZSH/oh-my-zsh.sh

alias -g gpi='| grep -i'

export PATH=/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
export PATH=/usr/local/sbin:$PATH
export EDITOR=vim
export PATH=/usr/local/go/bin:$PATH
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin
export PATH=/usr/local/heroku/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/Users/manu/go/bin:/Users/manu/.ec2/bin:/usr/local/libxls/bin
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Vi mode
set -o vi
bindkey -v

# cycle through arg history
bindkey '^O' insert-last-word

# bind k and j for VI mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Delay after <ESC> press in milisec (defaul = 4)
export KEYTIMEOUT=2

# chruby
source /usr/local/share/chruby/chruby.sh
chruby 2.3.0
