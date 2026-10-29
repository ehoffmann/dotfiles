set nocompatible
filetype off

" Resolve the ~/.vimrc symlink so the runtime follows this checkout.
let s:vim_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/vim'
" Keep these paths unique when reloading the vimrc.
" Commas need escaping in the list as well as in the :set argument.
let s:runtime_dir = escape(escape(s:vim_dir, ','), ' \')
let s:after_dir = escape(escape(s:vim_dir . '/after', ','), ' \')
execute 'set runtimepath-=' . s:runtime_dir
execute 'set runtimepath-=' . s:after_dir
execute 'set runtimepath^=' . s:runtime_dir
execute 'set runtimepath+=' . s:after_dir

" Preferences load in order; filetype overrides load through Vim's runtime.
for s:config in ['options', 'plugins']
  execute 'source ' . fnameescape(s:vim_dir . '/config/' . s:config . '.vim')
endfor

filetype plugin indent on
runtime macros/matchit.vim
syntax on

for s:config in ['appearance', 'mappings', 'autocmds']
  execute 'source ' . fnameescape(s:vim_dir . '/config/' . s:config . '.vim')
endfor

" Make personal commands available to .vim.custom on startup and reload.
" Each entry point has a guard for Vim's automatic plugin loading pass.
for s:plugin in glob(s:vim_dir . '/plugin/*.vim', 0, 1)
  execute 'source ' . fnameescape(s:plugin)
endfor

" Keep the existing per-project override, after personal preferences.
if filereadable('.vim.custom')
  source .vim.custom
endif
