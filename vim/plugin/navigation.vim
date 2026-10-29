if exists('g:loaded_dotfiles_navigation')
  finish
endif
let g:loaded_dotfiles_navigation = 1

function! Tabs() abort
  return navigation#tabs()
endfunction

function! Today() abort
  return navigation#today()
endfunction

command! Tabs call Tabs()
command! Today call Today()
