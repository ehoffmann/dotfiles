" Personal go settings, applied after the standard filetype plugin.
if exists('b:dotfiles_go_settings')
  finish
endif
let b:dotfiles_go_settings = 1

" Hide tab markers in Go buffers.
setlocal nolist

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal list<'
      \ . ' | unlet! b:dotfiles_go_settings'
