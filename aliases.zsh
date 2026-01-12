# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias dco='docker compose'
alias dcr='docker compose stop && docker compose up'
alias drm='docker rm $(docker ps -a -q)'
alias dsc='docker stop $(docker ps -q)'

# -----------------------------------------------------------------------------
# TMUX
# -----------------------------------------------------------------------------
alias tmxu='tmux'
alias mux=tmuxinator
alias tmuxconf="vim ~/.tmux.conf"
source ~/.bin/tmuxinator.zsh # tmuxinator completion/alias

# -----------------------------------------------------------------------------
# Project related
# -----------------------------------------------------------------------------
alias wk="mux work"
alias kr="mux kr"
alias prj="mux prj"
alias code="mux code"
alias dot="mux dotfiles"
alias leet="mux leet"
alias euler="mux euler"
alias srv="mux server"
alias stree="mux tree"
alias retake="sudo chown -R manu:manu ."
alias mto='curl -4 http://wttr.in/Marseille'
alias -g rgi='| rg -i'
alias -g gpi='| rg -i'
# remove vim swap file, with confirmation
alias rmswp="find . -name '*.swp' -exec rm -i '{}' \;"

# -----------------------------------------------------------------------------
# Config alias
# -----------------------------------------------------------------------------
alias zshconf="vim ~/.zshrc"
alias vimconf="vim ~/.vimrc"

# -----------------------------------------------------------------------------
# Ruby/Rails
# -----------------------------------------------------------------------------
alias rubytag='ctags -R --languages=ruby --exclude=.git --exclude=log .'

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
alias gb='git branch'
alias gss='git status --short'
alias gsb='git status --short -b'
alias glo='git log --oneline --decorate'
alias gco='git checkout'
alias gloo='git --no-pager log --oneline --decorate --color | head '
alias gla="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias glb="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
# Clean branches already merged on staging
alias git-clean-branch='git fetch; git branch --merged staging | egrep -v "(^\*|master|staging)" | xargs git branch -d'
