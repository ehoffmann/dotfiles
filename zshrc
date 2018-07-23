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
alias rubytag='ctags -R --languages=ruby --exclude=.git --exclude=log .'

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias gloo='git --no-pager log --oneline --decorate --color | head '
alias gla="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glb="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
alias git-clean-branch='git branch --merged | egrep -v "(^\*|master|staging)" | xargs git branch -d'

# -----------------------------------------------------------------------------
# Vagrant
# -----------------------------------------------------------------------------
alias vagrash='vagrant up && vagrant ssh'

# -----------------------------------------------------------------------------
# Spelling
# -----------------------------------------------------------------------------
alias tmxu=tmux

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dco='docker-compose'
alias drm='docker rm $(docker ps -a -q)'

de() {
  docker exec -ti $1 bash
}

# Remove untaged images
drmi() {
  docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
}

# Remove all docker containers and images
drmall() {
  docker rm $(docker ps -a -q)
  docker rmi $(docker images -q)
}

dcr() {
  docker-compose run --rm web $@
}

railsc() {
  docker-compose run --rm web /bin/bash -c "echo 'set editing-mode vi' >> ~/.inputrc; bundle exec rails c"
}

dcba() {
  docker-compose run --rm web bash
}

dcbe() {
  docker-compose run --rm web bundle exec $@
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

dcmigrate_all() {
  dcmigrate_dev
  dcmigrate_test
}

dcmigrate_dev() {
  docker-compose run --rm web bundle exec rake db:migrate
}

dcmigrate_test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:migrate
}

dcrollback_dev() {
  docker-compose run --rm web bundle exec rake db:rollback
}

dcrollback_test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:rollback
}

dcdbreset_test() {
  #docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:environment:set
  #bin/rails db:environment:set RAILS_ENV=test
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:environment:set db:drop db:create db:schema:load
}

dcdbreset_dev() {
  docker-compose run --rm web bundle exec rake db:drop db:create db:schema:load
}

tco_mysql() {
  rails_env=${1:-development}
  docker-compose start mysql
  container=$(docker-compose ps mysql | grep Up | awk  '{print $1}')
  docker exec -ti $container mysql -uroot -pfoo tco_$rails_env
}

db_catalog() {
  rails_env=${1:-development}
  docker-compose start postgresql
  container=$(docker-compose ps postgresql | grep Up | awk  '{print $1}')
  docker exec -ti $container psql -U postgres catalog_$rails_env
}

db_shell() {
  docker-compose start db
  container=$(docker-compose ps db | grep Up | awk  '{print $1}')
  docker exec -ti $container psql -U postgres -W postgres
}

# load with
# zcat ../../dumps/teezily-04_23_2018_08_41_11-staging.sql.gz | docker exec -i teezily_mysql_1 mysql teezily_dev -uroot -pfoo
tz_dump() {
  branch_name=$(git rev-parse --abbrev-ref HEAD | sed -e 's/[^A-Za-z0-9._-]/_/g')
  file_path=/home/vagrant/dumps/teezily-$(date "+%m_%d_%Y_%H_%M_%S")-$branch_name.sql.gz
  db_dump mysql teezily_dev | gzip > $file_path
  echo "Dump OK -> $file_path"
}

db_dump() {
  docker-compose start $1
  container=$(docker-compose ps $1 | grep Up | awk  '{print $1}')
  docker exec -ti $container mysqldump -uroot -pfoo $2
}

keep_db_dump() {
  docker-compose start $1
  container=$(docker-compose ps $1 | grep Up | awk  '{print $1}')
  docker exec -ti $container mysqldump -uroot -pfoo tco_development
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

# -----------------------------------------------------------------------------
# linters
# -----------------------------------------------------------------------------

# Inspect current diff or from $1 commit earlier
rubo() {
  if [ -n "$1" ]
    git diff --name-status HEAD~"$1" HEAD | grep '^[A,M].*\.rb$' | cut -f2 | xargs -r rubocop --rails
    #git diff --name-status HEAD~"$1" HEAD | grep '^[A,M].*\.rb$' | cut -f2 
  then
    git diff --name-only --diff-filter=d | grep '.rb$' | xargs -r rubocop --rails
  else
  fi
}

rubs() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop --rails
}

rubc() {
  git diff-tree --no-commit-id --name-only -r `git rev-parse --short HEAD` | grep '.rb$' | xargs -r rubocop --rails
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
plugins=(git npm vagrant rails vi-mode history-substring-search zsh-syntax-highlighting)

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
alias mto='curl -4 http://wttr.in/Marseille'

# remove vim swap file, with confirmation
alias rmswp="find . -name '*.swp' -exec rm -i '{}' \;"
alias deschedule="sed -i 's/^\([^#]\)/#\1/g' config/schedule.rb"

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

# with up or down key
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Delay after <ESC> press in milisec (defaul = 4)
export KEYTIMEOUT=2

# Not to be disturbed by Ctrl-S Ctrl-Q in terminals
stty -ixon

# chruby
source /usr/local/share/chruby/chruby.sh
chruby 2.3.1

# tmuxinator completion
source ~/.bin/tmuxinator.zsh
