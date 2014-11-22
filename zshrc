# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="granutark"

# aliases
alias zshconf="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias vimconf="vim ~/.vimrc"
alias be='bundle exec'
alias brake='bundle exec rake'
alias glo='git log --oneline'
alias gpnew='git push origin new'
#alias current='cd ~/apps/activeandco.github.com && mvim . && jekyll serve -w'
alias current='cd ~/go/src/github.com/ehof'
# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git osx npm brew)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
export PATH=/usr/local/sbin:$PATH
# golang
export PATH=/usr/local/go/bin:$PATH
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin
export PATH=/usr/local/heroku/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/share/npm/bin:/Users/manu/.rbenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/Users/manu/go/bin:/Users/manu/.ec2/bin:/usr/local/libxls/bin
# For proper encoding with jekyll
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

### Vi mode

set -o vi
bindkey -v
# Delay after <ESC> press in milisec (defaul = 4)>
export KEYTIMEOUT=2

###

# EC2 stuffs
export EC2_HOME=~/.ec2
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=`ls $EC2_HOME/pk-*.pem`
export EC2_CERT=`ls $EC2_HOME/cert-*.pem`
export EC2_URL=https://ec2.eu-west-1.amazonaws.com
export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home/

# Search
#bindkey '^R' history-incremental-search-backward

# cycle throug arg history
bindkey '^O' insert-last-word



