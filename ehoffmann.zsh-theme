# ln -s ~/dotfiles/ehoffmann.zsh-theme ~/.oh-my-zsh/themes/
#
local ret_status="%(?:%{$fg_bold[cyan]%}➜:%{$fg_bold[red]%}➜)"
PROMPT='%{$fg[cyan]%}%c ${ret_status}%{$reset_color%} '
RPROMPT='$(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="⚡"
ZSH_THEME_GIT_PROMPT_CLEAN=""
