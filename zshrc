ZSH=$HOME/.oh-my-zsh

# ZSH_THEME="agnoster"
# ZSH_THEME="robbyrussell"
# ZSH_THEME="gruvbox"
# ZSH_THEME="terminalparty"
# ZSH_THEME="spaceship"
ZSH_THEME="ehoffmann"

# zsh builtin
autoload -U zmv

# Vi mode
set -o vi
bindkey -v

# Not to be disturbed by Ctrl-S Ctrl-Q in terminals
stty -ixon

# -----------------------------------------------------------------------------
# Config alias
# -----------------------------------------------------------------------------
alias zshconf="vim ~/.zshrc"
alias vimconf="vim ~/.vimrc"
alias tmuxconf="vim ~/.tmux.conf"
alias mux=tmuxinator

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
# Vagrant
# -----------------------------------------------------------------------------
alias vagrash='vagrant up && vagrant ssh'

# -----------------------------------------------------------------------------
# TMUX
# -----------------------------------------------------------------------------
alias tmxu='tmux'

# -----------------------------------------------------------------------------
# fzf
# -----------------------------------------------------------------------------
# Default fzf search for vim
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

# -----------------------------------------------------------------------------
# k8s deploy & console
# -----------------------------------------------------------------------------

k8s() {
  host=$(cat ~/.prod-k8s)
  ssh $host
}

# Launch a command into a themed terminal
g-term() { # $profile $command
  gnome-terminal --window-with-profile="$1" -- zsh -ic "$2"
}

# TZ Teezily
tz-deploy-branch() {
  REPO=basename `git rev-parse --show-toplevel`
  if [[ $REPO != teezily ]]
  then
    echo "Not in teezily"
    exit 1
  fi

  read REPLY\?"Deploy $1 to teezily-pr$2?"
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    docker-compose run --rm web bin/deploy-branch $1 teezily-pr$2 d
  fi
}

tz-enter-branch() {
  REPO=basename `git rev-parse --show-toplevel`
  if [[ $REPO != teezily ]]
  then
    echo Not in teezily
    exit 1
  fi
  docker-compose run --rm web bin/dokku-staging enter teezily-pr$1 web.1 bash
}

# update 2020-05-18 Does not work anymore, try instead:
# docker-compose run --rm web bin/dokku-staging enter teezily web.1 bash
# docker-compose run --rm web bin/dokku-staging enter teezily-prX web.1 bash
tz-staging() {
  _k8s "teezily-staging" "teezily-web" "bash"
}

tz-prod() {
  _k8s "teezily-prod" "toolbox" "bash"
}

# Pricing
pricing-staging() {
  _k8s "pricing-staging" "web" "bundle exec bash"
}

pricing-prod() {
  _k8s "pricing-prod" "web" "bundle exec bash"
}

# TCO
tco-prod() {
  g-term Prod "_k8s tco-prod toolbox bash"
}

tco-staging() {
  g-term Staging "_k8s tco-staging worker bash"
}

# PCO
pco-prod() {
  _k8s "pco-prod" "toolbox" "bash"
}

pco-staging() {
  _k8s "pco-staging" "web" "bash"
}

# valid-address
va-prod() {
  _k8s "valid-address-prod" "web" "bash"
}

va-staging() {
  _k8s "valid-address-staging" "web" "bash"
}

# T4B
t4b-prod() {
  g-term Prod "_k8s t4b-prod toolbox bash"
}

t4b-staging() {
  g-term Staging "_t4b-pr t4b-web-"
}

t4b-staging-redis() {
  g-term Staging "_t4b-pr t4b-redis- redis-cli"
}

t4b-staging-pr() {
  g-term Staging "_t4b-pr t4b-pr-web-"
}

t4b-staging-pr2() {
  g-term Staging "_t4b-pr t4b-pr2-web-"
}

t4b-staging-pr3() {
  g-term Staging "_t4b-pr t4b-pr3-web-"
}

_t4b-pr() {
  cd ~/code/tz/t4b || exit 1
  ARG2=${2:-bash}
  CONTAINER=`dco run --rm  web bin/kubectl-staging get pods | grep $1 | awk '{print $1}'`
  if [ -n "$CONTAINER" ]; then
    docker-compose run --rm web bin/kubectl-staging exec -it $CONTAINER  -- $ARG2
  else
    echo "No container."
  fi
}

# tsp tshir-previewer
tsp-prod() {
  _k8s "tshirt-previewer-prod" "toolbox" "bash"
}

tsp-staging() {
  _k8s "tshirt-previewer-staging" "web" "bash"
}

# Edit branch name
# Don't forget to rollback
tsp-edit-staging() {
  # REPO=basename `git rev-parse --show-toplevel`
  # if [[ $REPO != tshirt-previewer ]]
  # then
    # echo Not in tsp
    # exit 1
  # fi
  docker-compose run --rm web bin/kubectl-staging edit deployment tshirt-previewer-web
}

# mockup-creator-module mcm
mcm-edit-staging() {
  # REPO=basename `git rev-parse --show-toplevel`
  # if [[ $REPO != tshirt-previewer ]]
  # then
    # echo Not in tsp
    # exit 1
  # fi
  docker-compose run --rm web bin/kubectl-staging edit deployment mockup-creator-module-web
}

mcm-bash-staging() {
  _k8s "mockup-creator-module-staging" "web" "bash"
}

# Reprint
reprint-prod() {
  _k8s "reprint-prod" "web" "bash"
}

reprint-staging() {
  _k8s "reprint-staging" "web" "bash"
}

# -----------------------------------------------------------------------------
# k8s tools
# -----------------------------------------------------------------------------

staging-images () {
  for cont in $(bin/kubectl-staging get pods -o name); do
    cont=${cont#pod/}
    image=$(bin/kubectl-staging get pod $cont -o yaml | egrep  -o -m 1 '  image: .*')
    echo "$cont $image"
  done
}

_k8s() {
  host=$(cat ~/.prod-k8s)
  ssh -t $host "kubectl -n $1 get pods | grep $2 | awk '{print\$1}' | xargs -to -i{} kubectl -n $1 exec -it {} $3"
}

# -----------------------------------------------------------------------------
# Kubetail
# -----------------------------------------------------------------------------

kubetail-t4b() {
  _kubetail-prod "$1" "t4b-prod"
}

kubetail-tco() {
  _kubetail-prod "$1" "tco-prod"
}

kubetail-pco() {
  _kubetail-prod "$1" "pco-prod"
}

kubetail-tsp() {
  _kubetail-prod "$1" "tshirt-previewer-prod"
}

kubetail-pricing() {
  _kubetail-prod "$1" "pricing-prod"
}

_kubetail-prod() {
  host=$(cat ~/.prod-k8s)
  ssh -t $host "kubetail $1 -n $2"
}

# Require ssh access to staging host
# _kubetail-staging() {
#   host=$(cat ~/.staging-k8s)
#   ssh -t $host "kubetail $1 -n $2"
# }

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dco='docker-compose'
alias dcr='docker-compose stop && docker-compose up'
alias drm='docker rm $(docker ps -a -q)'
alias dsc='docker stop $(docker ps -q)'

# Remove untaged images
drmi() {
  docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
}

# Remove all docker containers and images
drmall() {
  docker rm $(docker ps -a -q)
  docker rmi $(docker images -q)
}

rb() {
  docker-compose run --rm web /bin/bash -c "echo 'set editing-mode vi' >> ~/.inputrc; echo '\"jk\": vi-movement-mode' >> ~/.inputrc; bundle exec rails c"
}

# In adition, we can use new docker exec feature to work with running container:
# docker exec -it <container_id> bash -c 'cat > /path/to/container/file' <
# /path/to/host/file/

rbtz() {
  docker-compose run --rm web /bin/bash
}
cptz() {
  docker exec -i $1 bash -c 'cat > ~/.irbrc' < ~/.irbrc
}

tza-rb() {
  docker-compose -f docker-compose.yml -f docker-compose.analytics.yml run --rm web bash
}

dcba() {
  docker-compose run --rm web /bin/bash -c "echo 'set editing-mode vi' >> ~/.inputrc; bash"
}

dcbe() {
  docker-compose run --rm web bundle exec $@
}

dcguard() {
  docker-compose run --rm web bundle exec guard -g spec
}

tzguard() {
  # Mysql with tmpfs
  # guard -i => get term input echo with binding.pry
  docker-compose run --rm web /bin/bash -c "RAILS_ENV=test bundle exec rake db:create db:schema:load && bundle exec guard -i"
}

tzspec() {
  # Mysql with tmpfs
  # guard -i => get term input echo with binding.pry
  docker-compose run --rm web /bin/bash -c "RAILS_ENV=test bundle exec rake db:create db:schema:load && bundle exec rspec"
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

dcmigrate-test-noset() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake RAILS_ENV=test db:drop db:create db:test:prepare
}

dcrollback-dev() {
  docker-compose run --rm web bundle exec rake db:rollback
}

dcrollback-test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:rollback
}

dcdbreset-test() {
  docker-compose run --rm -e RAILS_ENV=test web bundle exec rake db:drop db:create db:schema:load
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

# load with `rake db:create`
# zcat ../../dumps/teezily-04_23_2018_08_41_11-staging.sql.gz | docker exec -i teezily_mysql_1 mysql teezily_dev -uroot -pfoo
tz-dump() {
  branch_name=$(git rev-parse --abbrev-ref HEAD | sed -e 's/[^A-Za-z0-9._-]/_/g')
  file_path=~/dumps/teezily-$(date "+%m_%d_%Y_%H_%M_%S")-$branch_name.sql.gz
  db-dump mysql teezily_dev | gzip > $file_path
  echo "Dump OK -> $file_path"
}

pm-dump() {
  _pg-dump product_manager_development
}

tsp-dump() {
  _pg-dump tshirt-previewer_development
}

_pg-load() {
  container=$(docker-compose ps -q postgresql)
  zcat $1 | docker exec -i $container psql $2 -Upostgres -W foo                                                                │
}

_pg-dump() {
  branch_name=$(git rev-parse --abbrev-ref HEAD | sed -e 's/[^A-Za-z0-9._-]/_/g')
  file_path=~/dumps/$1-$(date "+%m_%d_%Y_%H_%M_%S")-$branch_name.sql
  docker-compose start postgresql
  container=$(docker-compose ps -q postgresql)
  if [ -z "$container" ]
  then
    echo "Container is not running"
    exit 1
  else
    docker exec -ti $container pg_dump -U postgres $1 > $file_path
    if [ $? -eq 0 ]
    then
      gzip $file_path
      echo "Dump OK"
      echo "$file_path.gz"
    else
      echo "Dump KO"
    fi
  fi
}

mysql-dump() {
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
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop
}

rubsa() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop --auto-correct
}

# Not sure about the relevance of this one
rubc() {
  git diff-tree --no-commit-id --name-only -r `git rev-parse --short HEAD` | grep '.rb$' | xargs -r rubocop
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
alias devops="mux devops"
alias tz="mux teezily"
alias tza="mux tza"
alias pm="mux product-manager"
alias dot="mux dotfiles"
alias ali="mux aliproxy"
alias ful="mux fulfillment"
alias catalog="mux catalog"
alias catalogc="mux catalog_client"
alias tco="mux tco"
alias tcoc="mux tco_client"
alias delc="mux delivengo_client"
alias pco="mux pco"
alias wk="mux work"
alias t4b="mux t4b"
alias t4b_slate="mux t4b_slate"
alias t4b-woo="mux t4b-woo"
alias t4b-woo-svn="mux t4b-woo-svn"
alias tsp="mux tsp"
alias woo="mux woo"
alias mcm="mux mcm"
alias pricing="mux pricing"
alias vac="mux valid_address_client"
alias va="mux valid_address"
alias reprint="mux reprint"
alias code="mux code"
alias prod="mux prod"
alias ctza="docker-compose -f docker-compose.yml -f docker-compose.analytics.yml up"
alias retake="sudo chown -R manu:manu ."
alias -g gpi='| grep -i'
alias mto='curl -4 http://wttr.in/Marseille'
alias postman=~/bin/Postman
alias gno=gnome-open
# remove vim swap file, with confirmation
alias rmswp="find . -name '*.swp' -exec rm -i '{}' \;"

# -----------------------------------------------------------------------------
# oh-my-zsh
# -----------------------------------------------------------------------------
source $ZSH/oh-my-zsh.sh

# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
export PATH=/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
export PATH=/usr/local/sbin:$PATH
export EDITOR=vim
export PATH=/usr/local/go/bin:$PATH
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin
export PATH=/usr/local/heroku/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/Users/manu/go/bin:/Users/manu/.ec2/bin:/usr/local/libxls/bin
export PATH="/home/vagrant/.gem/ruby/2.5.0/bin:$PATH"
export PATH=/usr/bin/vendor_perl:$PATH
export PATH=/usr/games:$PATH
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# cycle through arg history
bindkey '^O' insert-last-word

# bind k and j for VI mode (history-substring-search plugin)
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Delay after <ESC> press in milisec (defaul = 4)
export KEYTIMEOUT=10

# chruby
source /usr/local/share/chruby/chruby.sh
# (installed with `sudo ruby-install ruby 2.6.9`)
chruby 2.6.9

# tmuxinator completion/alias
source ~/.bin/tmuxinator.zsh

# Zsh syntax hi
source ~/code/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
