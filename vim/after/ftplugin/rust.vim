" Personal rust settings, applied after the standard filetype plugin.
if exists('b:dotfiles_rust_settings')
  finish
endif
let b:dotfiles_rust_settings = 1

setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" Save and cargo run in Rust buffers.
inoremap <buffer> <C-s> <Esc>:update<CR>:! cargo run<CR>

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal tabstop< softtabstop< shiftwidth< expandtab<'
      \ . ' | silent! iunmap <buffer> <C-s>'
      \ . ' | unlet! b:dotfiles_rust_settings'
