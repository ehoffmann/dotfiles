" Personal fern settings, applied after the standard filetype plugin.
if exists('b:dotfiles_fern_settings')
  finish
endif
let b:dotfiles_fern_settings = 1

nnoremap <buffer> <silent> <C-h> :TmuxNavigateLeft<CR>
nnoremap <buffer> <silent> <C-j> :TmuxNavigateDown<CR>
nnoremap <buffer> <silent> <C-k> :TmuxNavigateUp<CR>
nnoremap <buffer> <silent> <C-l> :TmuxNavigateRight<CR>

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'silent! nunmap <buffer> <C-h>'
      \ . ' | silent! nunmap <buffer> <C-j>'
      \ . ' | silent! nunmap <buffer> <C-k>'
      \ . ' | silent! nunmap <buffer> <C-l>'
      \ . ' | unlet! b:dotfiles_fern_settings'
