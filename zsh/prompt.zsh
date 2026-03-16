setopt promptsubst

function _vi_update_prompt() {
  if [[ $KEYMAP == vicmd ]]; then
    # VI_PROMPT_ARROW='❮'
    VI_PROMPT_ARROW='<esc> '
  else
    # VI_PROMPT_ARROW='❯'
    VI_PROMPT_ARROW=''
  fi
}

function zle-keymap-select {
  _vi_update_prompt
  zle reset-prompt
}
zle -N zle-keymap-select

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}(%b|%a)%f'

function git_dirty() {
  git rev-parse --is-inside-work-tree &>/dev/null &&
  ! git diff --quiet && echo ' %F{yellow}⚡%f'
}

precmd() {
  local st=$?
  vcs_info
  if (( st == 0 )); then
    PROMPT_ARROW_COLOR='%F{white}'
  else
    PROMPT_ARROW_COLOR='%F{red}'
  fi
  _vi_update_prompt
}

PROMPT='${PROMPT_ARROW_COLOR}%#${VI_PROMPT_ARROW}%f '
RPROMPT='%F{blue}%~%f ${vcs_info_msg_0_}$(git_dirty)'
