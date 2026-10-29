let g:gutentags_modules = ['ctags']

call plug#begin('~/.vim/plugged')

" Interpret a file by function and cache file automatically, used by
" other plugin
Plug 'MarcWeber/vim-addon-mw-utils'

" Snippets
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'

" Fern
Plug 'lambdalisue/vim-fern'
Plug 'lambdalisue/vim-fern-git-status'

" Vim script for text filtering and alignment
Plug 'godlygeek/tabular'

" Fuzzy file finder
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Comment
Plug 'tomtom/tcomment_vim'

" Some utility functions for VIM
Plug 'tomtom/tlib_vim'

" Ruby support
Plug 'vim-ruby/vim-ruby'

" Required for 'nelstrom/vim-textobj-rubyblock'
Plug 'kana/vim-textobj-user'

" New text objects, al 'a line' and il 'inner line'
Plug 'kana/vim-textobj-line'

" Text objects for indented blocks of lines
Plug 'kana/vim-textobj-indent'

" Ruby text object
Plug 'nelstrom/vim-textobj-rubyblock'

" Indent-level based motion.
Plug 'jeetsukumaran/vim-indentwise'

" Git wrapper
Plug 'tpope/vim-fugitive'
Plug 'shumphrey/fugitive-gitlab.vim'

" GitHub extension for fugitive.vim, GBrowse, hub, completion in commit msg
Plug 'tpope/vim-rhubarb'

" Dot repeat at plugin level
Plug 'tpope/vim-repeat'

" Quoting/parenthesizing made simple
Plug 'tpope/vim-surround'

" Easily search for, substitute, and abbreviate multiple variants of a word
Plug 'tpope/vim-abolish'

" Rails
Plug 'tpope/vim-rails'

" Retro groove color scheme for Vim
Plug 'morhetz/gruvbox'

" Transparent editing of gpg encrypted files
Plug 'jamessan/vim-gnupg'

" Navigate seamlessly between vim and tmux splits
Plug 'christoomey/vim-tmux-navigator'

" Simplifies the transition between multiline and single-line code
Plug 'andrewradev/splitjoin.vim'

" Toggle ruby block with <Leader>b
Plug 'jgdavey/vim-blockle'

" Perform an interactive diff on two blocks of text
Plug 'AndrewRadev/linediff.vim'

" A git diff in the gutter (sign column), stages/undoes hunks and partial hunks.
Plug 'airblade/vim-gitgutter'

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Plugin variables must be set before plug#end() enables filetype plugins.
let g:fern#default_hidden = 1
let g:fern#drawer_width = 40
let g:tmux_navigator_disable_when_zoomed = 1
let g:snipMate = {'snippet_version': 1}

" Syntax
let g:ruby_space_errors = 1
let g:ruby_operators = 1
let g:ruby_pseudo_operators = 1
let g:ruby_line_continuation_error = 1
let g:ruby_global_variable_error = 1
let g:ruby_spellcheck_strings = 1

let g:markdown_fenced_languages = ['c', 'ruby', 'js=javascript', 'json', 'yaml', 'bash=sh', 'html']

let g:fugitive_gitlab_domains = {
      \ 'gitlab.myjungly.com': 'https://gitlab.myjungly.com'
      \ }

" Larger configurations keep their own feature files.
let s:config_dir = expand('<sfile>:p:h')
execute 'source ' . fnameescape(s:config_dir . '/tags.vim')
execute 'source ' . fnameescape(s:config_dir . '/rails.vim')

call plug#end()

" Vim's built-in debugger.
packadd termdebug
let g:termdebug_config = {
      \ 'wide': 1,
      \ 'variables_window': v:true,
      \ 'variables_window_height': 12,
      \ 'disasm_window': v:false,
      \ 'disasm_window_height': 1,
      \ 'popup': 1,
      \ 'sign': '>>',
      \}
