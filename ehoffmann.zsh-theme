# ln -s ~/dotfiles/ehoffmann.zsh-theme ~/.oh-my-zsh/themes/
#
# local ret_status="%(?:%{$fg_bold[cyan]%}➜ :%{$fg_bold[red]%}➜ )"
# PROMPT='%{$fg_bold[blue]%}%c ${ret_status} %{$reset_color%} '
# RPROMPT='$(git_prompt_info)'
# ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
# ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
# ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
# ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# New

#local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
#PROMPT='${ret_status} %{$fg[cyan]%}%c%{$reset_color%} '
#RPROMPT='$(git_prompt_info)'

local ret_status="%(?:%{$fg_bold[cyan]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT='%{$fg[blue]%}%c ${ret_status} %{$reset_color%} '
RPROMPT='$(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%} ⚡%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

#LCHAR_WIDTH=%1G

#LCHAR='$'

#PROMPT='%{$fg[cyan]%}%c %{$fg[white]%}%{$LCHAR$LCHAR_WIDTH%} %{$reset_color%}'
#
#ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}"
#ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$reset_color%}"
#ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*"
#

# PROMPT='%(?,%{$fg[green]%},%{$fg[red]%}) %% '
# # RPS1='%{$fg[blue]%}%~%{$reset_color%} '
# RPS1='%{$fg[white]%}%2~$(git_prompt_info) %{$fg_bold[blue]%}%m%{$reset_color%}'
#
# ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[yellow]%}("
# ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%}"
# ZSH_THEME_GIT_PROMPT_CLEAN=""
# ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%} ⚡%{$fg[yellow]%}"
