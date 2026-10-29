" Personal c settings, applied after the standard filetype plugin.
if exists('b:dotfiles_c_settings')
  finish
endif
let b:dotfiles_c_settings = 1

setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
setlocal makeprg=make\ -k\ NAME=%:r
setlocal errorformat=%f:%l:%c:\ %m

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal tabstop< softtabstop< shiftwidth< expandtab< makeprg< errorformat<'
      \ . ' | unlet! b:dotfiles_c_settings'
