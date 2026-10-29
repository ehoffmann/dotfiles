if exists('g:loaded_dotfiles_glow')
  finish
endif
let g:loaded_dotfiles_glow = 1

function! Glow() abort
  return glow#open()
endfunction

command! Glow call Glow()
