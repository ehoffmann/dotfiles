if exists('g:loaded_dotfiles_rubytools')
  finish
endif
let g:loaded_dotfiles_rubytools = 1

function! OpenRubyAPI() abort
  return rubytools#api()
endfunction

function! OpenCorrespondingSpec() abort
  return rubytools#spec()
endfunction

command! OpenSpec call OpenCorrespondingSpec()
