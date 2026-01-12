VI_PROMPT_ARROW='❯'

function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]]; then
    VI_PROMPT_ARROW='❮'
  else
    VI_PROMPT_ARROW='❯'
  fi
  zle reset-prompt
}
zle -N zle-keymap-select

autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}(%b|%a)%f'

git_dirty() {
  git rev-parse --is-inside-work-tree &>/dev/null &&
  ! git diff --quiet && echo '*'
}

precmd() {
  local st=$?
  vcs_info
  if (( st == 0 )); then
    PROMPT_ARROW_COLOR='%F{white}'
  else
    PROMPT_ARROW_COLOR='%F{red}'
  fi
}
PROMPT='%F{green}%n@%m%f %F{blue}%~%f ${vcs_info_msg_0_}$(git_dirty)
${PROMPT_ARROW_COLOR}${VI_PROMPT_ARROW}%f '

