" Personal qf settings, applied after the standard filetype plugin.
if exists('b:dotfiles_qf_settings')
  finish
endif
let b:dotfiles_qf_settings = 1

nnoremap <buffer> gd :call GitQfDiff()<CR>
nnoremap <buffer> gc :call GitQfReviewCommit()<CR>

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'silent! nunmap <buffer> gd'
      \ . ' | silent! nunmap <buffer> gc'
      \ . ' | unlet! b:dotfiles_qf_settings'
