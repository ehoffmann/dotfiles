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
" Use navite C-]
silent! nunmap <buffer> <C-]>
