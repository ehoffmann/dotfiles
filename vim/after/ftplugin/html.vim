" Personal html settings, applied after the standard filetype plugin.
if exists('b:dotfiles_html_settings')
  finish
endif
let b:dotfiles_html_settings = 1

setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal tabstop< softtabstop< shiftwidth< expandtab<'
      \ . ' | unlet! b:dotfiles_html_settings'
