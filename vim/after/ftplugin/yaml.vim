" Personal yaml settings, applied after the standard filetype plugin.
if exists('b:dotfiles_yaml_settings')
  finish
endif
let b:dotfiles_yaml_settings = 1

setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab autoindent
setlocal foldmethod=indent foldlevel=99

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent< foldmethod< foldlevel<'
      \ . ' | unlet! b:dotfiles_yaml_settings'
