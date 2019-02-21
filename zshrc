ZSH=$HOME/.oh-my-zsh

export TERM=xterm-256color
#export TERM=screen-256color-bce

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="ehoffmann"

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
# TMUX
# -----------------------------------------------------------------------------
alias tmxu='tmux'

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

rb() {
  docker-compose run --rm web /bin/bash -c "echo 'set editing-mode vi' >> ~/.inputrc; bundle exec rails c"
}

tza-rb() {
docker-compose -f docker-compose.yml -f docker-compose.analytics.yml run --rm web rails c
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

tzguard() {
  # Mysql with tmpfs
  # guard -i => get term input echo with binding.pry
  docker-compose run --rm web /bin/bash -c "RAILS_ENV=test bundle exec rake db:create db:schema:load && bundle exec guard -i"
}

dcguard_xfvb() {
  docker rm -f guard
  docker-compose run -d --rm --name guard web tail -f /dev/null
  docker exec -d guard sh -c 'Xvfb :99 -ac &'
  docker exec -ti guard sh -c 'export DISPLAY=:99; bundle exec guard'
}

dcmigrate-all() {
  dcmigrate_dev
  dcmigrate_test
}

dcmigrate-dev() {
  docker-compose run --rm web bundle exec rake db:migrate
}

dcmigrate-test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:environment:set RAILS_ENV=test db:drop db:create db:test:prepare
}

dcrollback-dev() {
  docker-compose run --rm web bundle exec rake db:rollback
}

dcrollback-test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:rollback
}

dcdbreset-test() {
  #docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:environment:set
  #bin/rails db:environment:set RAILS_ENV=test
  #docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:environment:set db:drop db:create db:schema:load
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:drop db:create db:schema:load
}

dcdbreset-dev() {
  echo "You don't want to do that"
  #docker-compose run --rm web bundle exec rake db:drop db:create db:schema:load
}

tco-mysql() {
  rails_env=${1:-development}
  docker-compose start mysql
  container=$(docker-compose ps mysql | grep Up | awk  '{print $1}')
  docker exec -ti $container mysql -uroot -pfoo tco_$rails_env
}

db-catalog() {
  rails_env=${1:-development}
  docker-compose start postgresql
  container=$(docker-compose ps postgresql | grep Up | awk  '{print $1}')
  docker exec -ti $container psql -U postgres catalog_$rails_env
}

pg-shell() {
  docker-compose start db
  container=$(docker-compose ps db | grep Up | awk  '{print $1}')
  docker exec -ti $container psql -U postgres -W postgres
}

tz-mysql-upgrade() {
  docker-compose start mysql
  container=$(docker-compose ps mysql | grep Up | awk  '{print $1}')
  docker exec -ti $container mysql_upgrade --user=root --password=foo
}

# load with
# zcat ../../dumps/teezily-04_23_2018_08_41_11-staging.sql.gz | docker exec -i teezily_mysql_1 mysql teezily_dev -uroot -pfoo
tz-dump() {
  branch_name=$(git rev-parse --abbrev-ref HEAD | sed -e 's/[^A-Za-z0-9._-]/_/g')
  file_path=/home/vagrant/dumps/teezily-$(date "+%m_%d_%Y_%H_%M_%S")-$branch_name.sql.gz
  db-dump mysql teezily_dev | gzip > $file_path
  echo "Dump OK -> $file_path"
}

pm-dump() {
  branch_name=$(git rev-parse --abbrev-ref HEAD | sed -e 's/[^A-Za-z0-9._-]/_/g')
  file_path=/home/vagrant/dumps/pm-$(date "+%m_%d_%Y_%H_%M_%S")-$branch_name.sql.gz
  docker-compose start postgresql
  container=$(docker-compose ps postgresql | grep Up | awk  '{print $1}')
  docker exec -ti $container pg_dump -U postgres product_manager_development | gzip > $file_path
  echo "Dump OK -> $file_path"
}

db-dump() {
  docker-compose start $1
  container=$(docker-compose ps $1 | grep Up | awk  '{print $1}')
  docker exec -ti $container mysqldump -uroot -pfoo $2
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
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop --rails
}

# Not sure about the relevance of this one
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
# Project related
# -----------------------------------------------------------------------------
alias devops="mux devops"
alias tz="mux teezily"
alias tza="mux tza"
alias pm="mux product-manager"
alias dot="mux dotfiles"
alias ali="mux aliproxy"
alias ful="mux fulfillment"
alias catalog="mux catalog"
alias tco= "mux tco"
alias wk="mux work"
alias ctza="docker-compose -f docker-compose.yml -f docker-compose.analytics.yml up"
alias retake="sudo chown -R manu:manu db/migrate"

# -----------------------------------------------------------------------------
# Misc
# -----------------------------------------------------------------------------
source $ZSH/oh-my-zsh.sh
alias -g gpi='| grep -i'
alias mto='curl -4 http://wttr.in/Marseille'

# remove vim swap file, with confirmation
alias rmswp="find . -name '*.swp' -exec rm -i '{}' \;"

export PATH=/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
export PATH=/usr/local/sbin:$PATH
export EDITOR=vim
export PATH=/usr/local/go/bin:$PATH
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin
export PATH=/usr/local/heroku/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/Users/manu/go/bin:/Users/manu/.ec2/bin:/usr/local/libxls/bin
export PATH="/home/vagrant/.gem/ruby/2.5.0/bin:$PATH"
export PATH=/usr/bin/vendor_perl:$PATH
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Vi mode
set -o vi
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode # require KEYTIMEOUT >= 10

# !! override theme
function zle-line-init zle-keymap-select {
    RPS1="$(git_prompt_info) ${${KEYMAP/vicmd/[CMD]}/(main|viins)/}"
    RPS2=$RPS1
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# cycle through arg history
bindkey '^O' insert-last-word

# bind k and j for VI mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# with up or down key
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Delay after <ESC> press in milisec (defaul = 4)
export KEYTIMEOUT=10

# Not to be disturbed by Ctrl-S Ctrl-Q in terminals
stty -ixon

# chruby
source /usr/local/share/chruby/chruby.sh
chruby 2.5.1

# tmuxinator completion
source ~/.bin/tmuxinator.zsh

#source ~/code/gruvbox/gruvbox_256palette.sh
source ~/code/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
