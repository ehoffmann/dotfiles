" Personal ruby settings, applied after the standard filetype plugin.
if exists('b:dotfiles_ruby_settings')
  finish
endif
let b:dotfiles_ruby_settings = 1

setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
setlocal path+=lib/,app/

" Workaround: vim-ruby ftplugin resets &l:tags and drops Gutentags' cached
" tags file. Since after/ftplugin/ruby.vim runs afterwards, restore it here.
"
" Symptom:
"   E433: No tags file
"   E426: Tag not found: ...
"
" Diagnosed 2026-09-10.
if exists('b:gutentags_files') && has_key(b:gutentags_files, 'ctags')
  execute 'setlocal tags+=' . fnameescape(b:gutentags_files.ctags)
endif
setlocal iskeyword+=!
setlocal iskeyword+=?
" Use Ruby-aware tag navigation with the native tag stack.
nnoremap <buffer> <silent> <C-]> :call rubytag#jump()<CR>

" Ruby 1.9 hash: convert from `':test' => 123` to `test: 123`,
" memo: Colon
nnoremap <buffer> <leader>hc :s/:\([^ ]*\)\(\s*\)=>/\1:/g<cr>

" Rocket to Hash convert "id"=>"1" to id: "1",
" memo: Hash
nnoremap <buffer> <leader>hh :s/["']\(\w*\)["']\(\s*\)=>\s*/\1: /g<CR>

" Hash to Rocket id: "1" to "id" => "1"
" memo: Rocket
nnoremap <buffer> <leader>hr :s/\(\w*\):\s*/'\1' => /g<CR>

" Fold all `def`, unfold with zR
nnoremap <buffer> <leader>fr :g/^\s*def\s/normal zfam<CR>

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal tabstop< softtabstop< shiftwidth< expandtab< path< tags< iskeyword<'
      \ . ' | silent! nunmap <buffer> <C-]>'
      \ . ' | silent! nunmap <buffer> <leader>hc'
      \ . ' | silent! nunmap <buffer> <leader>hh'
      \ . ' | silent! nunmap <buffer> <leader>hr'
      \ . ' | silent! nunmap <buffer> <leader>fr'
      \ . ' | unlet! b:dotfiles_ruby_settings'
