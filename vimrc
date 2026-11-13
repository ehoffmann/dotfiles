" Vim configuration in one file. Sections fold with markers: zM closes them
" all, za toggles one. Code loaded on demand stays in vim/autoload/, and
" overrides that must run after Vim's indent or syntax scripts stay in
" vim/after/.

" Runtime path {{{1
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

" Options {{{1
set encoding=utf-8
set synmaxcol=1024  " Avoid slow syntax highlighting on very long lines.
set noeb vb t_vb=   " Disable error bell

set number
set ruler
set scrolloff=3
" set scrolloff=999

" Buffer switching behavior
" set hidden
set confirm

" Required for 'git review' custom alias
set tabpagemax=100

" Search {{{2
set incsearch
set showmatch
set ignorecase  " ignore case when searching
set smartcase   " override 'ignorecase' if pattern contains uppercase - ignorecase should be set

" Indentation {{{2
set tabstop=2                   " a tab is two spaces
set shiftwidth=2                " an autoindent (with <<) is two spaces
set expandtab                   " use spaces, not tabs
set backspace=indent,eol,start  " backspace through everything in insert mode

" Wrap {{{2
set wrap                        " wrap lines
set linebreak                   " breaks by word rather than character
set breakindent                 " wrapped line visually indented (same amount as the beginning line)
set showbreak=↪\                " break symbol

" Mouse, views, diff and clipboard {{{2
set mouse=a
if !has('nvim')
  if has('mouse_sgr')
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  endif
endif

" Save folds without restoring unrelated options.
set viewoptions-=options

" Git gutter and diff defaults.
set updatetime=750
set diffopt+=iwhite

" Global ignore
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/Cache/*

" Use clipboard. https://stackoverflow.com/a/30691754/1876625
set clipboard^=unnamed,unnamedplus

" Plugins {{{1
" Plugin variables must be set before plug#end() enables filetype plugins.
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

" Plugin variables {{{2
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

" Tags (Gutentags) {{{2
" Keep generated tag files outside repositories.
let g:gutentags_cache_dir = expand('~/.cache/vim/gutentags')

" Explicitly use Universal Ctags.
let g:gutentags_ctags_executable = 'ctags'

" Let Git decide which files belong to the project:
"   -c: tracked files
"   -o: untracked files
"   --exclude-standard: respect .gitignore, .git/info/exclude and global ignore
let g:gutentags_file_list_command = {
      \ 'markers': {
      \   '.git': 'git ls-files -co --exclude-standard'
      \ }
      \ }

" Generate qualified entries such as namespaced classes and scoped methods.
let g:gutentags_ctags_extra_args = ['--extras=+q', '--fields=+nKS']

" Useful if some generated directories contain tracked files.
let g:gutentags_ctags_exclude = [
      \ 'log/*',
      \ 'tmp/*',
      \ 'storage/*',
      \ 'coverage/*',
      \ 'node_modules/*',
      \ 'vendor/*',
      \ 'public/assets/*',
      \ 'public/packs/*'
      \ ]

" These are defaults, but keeping them explicit documents the behaviour.
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_background_update = 1

" Optional status-line indicator while ctags is running.
let s:status = "%{gutentags#statusline('[',']')}"
if stridx(&statusline, s:status) < 0
  let &statusline .= s:status
endif

" Jump immediately when unique; show the selection list when ambiguous.
" nnoremap <C-]> g<C-]>

" Open in new tab
nnoremap <leader>] :tab tag <C-R><C-W><CR>

" Open in new split
nnoremap <leader>[ :stag <C-R><C-W><CR>

" Useful native commands:
" CTRL-]          Jump to definition; mapped above
" g]              Always show all matching tags
" CTRL-T          Return through the tag stack
" :tags           Display the current tag stack
" :tnext          Next matching tag
" :tprevious      Previous matching tag
" CTRL-W g CTRL-] Open the definition in a split
"
" Vim maintains a real tag stack, so CTRL-T is preferable to relying exclusively on CTRL-O
"
" A Normal workflow would be:
"
" CTRL-]       Symbol directly under cursor
" g]           Inspect ambiguous definitions
" :Tags Foo    Search for an approximately known class or method
" :BTags       Browse the structure of a large current file
" CTRL-T       Return

" Rails projections {{{2
" - Navigation between services and specs
" - Navigation controller and request specs
" - typing `:Efactory user` will open the user factory
"
let g:rails_projections = {
      \  "app/services/*_service.rb": {
      \    "command": "service",
      \    "template":
      \      ["module {camelcase|capitalize|dirname}",
      \       "  class {camelcase|capitalize|basename}Service",
      \       "    def call",
      \       "    end",
      \       "  end",
      \       "end"],
      \    "test": [
      \      "spec/services/{}_service_spec.rb"
      \    ]
      \  },
      \  "app/controllers/*_controller.rb": {
      \    "test": [
      \      "spec/requests/{}_spec.rb",
      \      "spec/requests/{}/index_spec.rb",
      \      "spec/requests/{}/create_spec.rb",
      \      "spec/requests/{}/show.rb",
      \      "spec/requests/{}/update_spec.rb",
      \      "spec/requests/{}/update_published.rb",
      \      "spec/requests/{}/delete_spec.rb",
      \    ]
      \  },
      \  "spec/requests/*_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/index_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/create_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/show_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/update_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/update_published_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/destroy_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/factories/*_factory.rb": {
      \    "command": "factory",
      \    "affinity": "collection",
      \    "alternate": "app/models/%i.rb",
      \    "related": "db/schema.rb#%s",
      \    "test": "spec/models/%i_spec.rb",
      \    "template": "FactoryGirl.define do\n  factory :%i do\n  end\nend",
      \    "keywords": "factory sequence"
      \  }
      \}

" End of plugin list {{{2
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

filetype plugin indent on
runtime macros/matchit.vim
syntax on

" Appearance {{{1
" Solarized (manual install from https://github.com/altercation/vim-colors-solarized/tree/master#option-1-manual-installation
" set background=dark
" let g:solarized_diffmode="high"
" let g:solarized_diffmode="low"
" colorscheme solarized

" Fix issue with spell check and solarized " https://github.com/altercation/vim-colors-solarized/issues/195
" set t_Cs=

" Gruvbox
" Vim only sets the true-color codes for xterm-like terminals; tmux reports
" tmux-256color, so set them there too.
if &term =~# '^\%(tmux\|screen\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set termguicolors
let g:gruvbox_italic=1
set background=light
colorscheme gruvbox
" let g:gruvbox_number_column='bg2'
" let g:gruvbox_color_column='bg3'

" Match fzf and its bat previews to the cream editor palette.
let g:fzf_colors = {
      \ 'fg': ['fg', 'Normal'],
      \ 'bg': ['bg', 'Normal'],
      \ 'fg+': ['fg', 'Normal'],
      \ 'bg+': ['bg', 'CursorLine'],
      \ 'preview-fg': ['fg', 'Normal'],
      \ 'preview-bg': ['bg', 'Normal'],
      \ 'hl': ['fg', 'Statement'],
      \ 'hl+': ['fg', 'Statement'],
      \ 'info': ['fg', 'PreProc'],
      \ 'border': ['fg', 'Comment'],
      \ 'prompt': ['fg', 'Conditional'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker': ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header': ['fg', 'Comment'],
      \ }
let $BAT_THEME = 'gruvbox-light'

" Highlight col 101 and onward
" let &colorcolumn=join(range(101,6999),",")

" Highlight tabs and trailing spaces
set list listchars=tab:→\ ,nbsp:␣,trail:•,precedes:«,extends:»

" Keep gutter styling when changing colorschemes interactively.
highlight! link SignColumn LineNr
augroup dotfiles_appearance
  autocmd!
  autocmd ColorScheme * highlight! link SignColumn LineNr
augroup END

" Mappings {{{1
" F7 switch to cp1252 encoding
nnoremap <F7> :e ++enc=cp1252<CR>

" F8 switch to UTF-8 encoding
nnoremap <F8> :e ++enc=utf-8<CR>

" Clean dirty file
nnoremap <F9> :retab<CR>:%s/\s*$//<CR>

" Search for visually selected text
vnoremap // y/<C-R>"<CR>

" Type "visual" yourself!
nnoremap Q <Nop>

" Swap quotes " for '
nmap <leader>q :s/"/'/g<CR>

" Normalize space between curly (depends on Surround.vim)
nmap <leader>cr cs{}cs}{

" Mark task as done
nmap <leader>x :s/\[ \]/[X]/<CR>

" Select pasted text visually
nnoremap gp `[v`]

" Toggle Fern and reveal the current file.
nnoremap <silent> <Leader>e
      \ :Fern . -drawer -toggle -reveal=%<CR>

command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
nmap <C-P> :Files!<CR>

" Rg
command! -bang -nargs=* Rg
      \ call fzf#vim#grep(
      \   'rg --column --line-number --no-heading --color=always
      \       --smart-case --hidden --no-ignore-vcs -- '
      \       . shellescape(<q-args>), 1, fzf#vim#with_preview(),
      \   <bang>0
      \ )
" Open Rg full screen
nnoremap <silent> <Leader>rg :Rg!<CR>
" Open Rg full screen, filled with word under cursor
nnoremap <silent> <Leader>rw :Rg! <C-R><C-W><CR>

" nnoremap <F5> :w<CR>:silent! :make<CR>:cwindow<CR>
nnoremap <leader>5 :update<CR>:silent! make \| redraw! \| cwindow<CR>
inoremap <leader>5 <Esc>:update<CR>:silent! make \| redraw! \| cwindow<CR>
" inoremap <F5> <Esc>:update<CR>:silent! make \| redraw! \| cwindow<CR>a

" Autocommands {{{1
" hlsearch only when cmd
augroup vimrc-incsearch-highlight
  autocmd!
  autocmd CmdlineEnter [\/\?] :set hlsearch
  autocmd CmdlineLeave [\/\?] :set nohlsearch
augroup END

augroup remember_folds
  autocmd!
  autocmd BufWinLeave * if &buftype ==# '' && !empty(expand('%:p')) | silent! mkview 1 | endif
  autocmd BufWinEnter * if &buftype ==# '' && !empty(expand('%:p')) | silent! loadview 1 | endif
augroup END

" Refresh the window's matches without accumulating them on every visit.
function! s:highlight_keywords() abort
  for id in get(w:, 'dotfiles_keyword_matches', [])
    silent! call matchdelete(id)
  endfor
  let w:dotfiles_keyword_matches = [
        \ matchadd('Error', 'BROKEN\|WTF', -1),
        \ matchadd('Todo', 'HACK\|BUG\|REVIEW\|FIXME\|TODO\|NOTE', -1),
        \ matchadd('Special', 'DONE', -1),
        \ ]
endfunction

augroup dotfiles_keywords
  autocmd!
  autocmd BufWinEnter * call s:highlight_keywords()
augroup END

" Filetypes {{{1
" Detection {{{2
augroup dotfiles_filetypes
  autocmd!
  autocmd BufNewFile,BufRead Guardfile setfiletype ruby
  autocmd BufNewFile,BufRead .env.local,*.env.* setfiletype sh
  autocmd BufNewFile,BufRead *.go setfiletype go
augroup END

" Settings {{{2
" Each s:ft_<name>() works like an after/ftplugin script: this FileType
" handler is defined after `filetype plugin on`, so it runs after Vim's
" ftplugins, and the cleanup it registers in b:undo_ftplugin runs when the
" buffer changes filetype. Dotted filetypes apply each part, like ftplugins.
function! s:apply_ftplugins() abort
  for l:name in split(&filetype, '\.')
    if l:name !~# '^\w\+$' || !exists('*s:ft_' . l:name)
      continue
    endif
    let l:guard = 'b:dotfiles_' . l:name . '_settings'
    if exists(l:guard)
      continue
    endif
    execute 'let ' . l:guard . ' = 1'
    call call(function('s:ft_' . l:name), [])
  endfor
endfunction

" Register cleanup for one filetype's settings and its guard variable.
function! s:undo_ftplugin(name, commands) abort
  let l:undo = get(b:, 'undo_ftplugin', '')
  let b:undo_ftplugin = l:undo . (empty(l:undo) ? '' : ' | ') . a:commands
        \ . ' | unlet! b:dotfiles_' . a:name . '_settings'
endfunction

function! s:ft_c() abort
  setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  setlocal makeprg=make\ -k\ NAME=%:r
  setlocal errorformat=%f:%l:%c:\ %m
  call s:undo_ftplugin('c',
        \ 'setlocal tabstop< softtabstop< shiftwidth< expandtab< makeprg< errorformat<')
endfunction

function! s:ft_fern() abort
  nnoremap <buffer> <silent> <C-h> :TmuxNavigateLeft<CR>
  nnoremap <buffer> <silent> <C-j> :TmuxNavigateDown<CR>
  nnoremap <buffer> <silent> <C-k> :TmuxNavigateUp<CR>
  nnoremap <buffer> <silent> <C-l> :TmuxNavigateRight<CR>
  call s:undo_ftplugin('fern', 'silent! nunmap <buffer> <C-h>'
        \ . ' | silent! nunmap <buffer> <C-j>'
        \ . ' | silent! nunmap <buffer> <C-k>'
        \ . ' | silent! nunmap <buffer> <C-l>')
endfunction

function! s:ft_go() abort
  " Hide tab markers in Go buffers.
  setlocal nolist
  call s:undo_ftplugin('go', 'setlocal list<')
endfunction

function! s:ft_html() abort
  setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  call s:undo_ftplugin('html', 'setlocal tabstop< softtabstop< shiftwidth< expandtab<')
endfunction

function! s:ft_javascript() abort
  setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  call s:undo_ftplugin('javascript', 'setlocal tabstop< softtabstop< shiftwidth< expandtab<')
endfunction

function! s:ft_qf() abort
  nnoremap <buffer> gd :call GitQfDiff()<CR>
  nnoremap <buffer> gc :call GitQfReviewCommit()<CR>
  call s:undo_ftplugin('qf', 'silent! nunmap <buffer> gd | silent! nunmap <buffer> gc')
endfunction

function! s:ft_ruby() abort
  setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  setlocal path+=lib/,app/

  " Workaround: vim-ruby ftplugin resets &l:tags and drops Gutentags' cached
  " tags file. This handler runs after it, so restore the file here.
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

  call s:undo_ftplugin('ruby',
        \ 'setlocal tabstop< softtabstop< shiftwidth< expandtab< path< tags< iskeyword<'
        \ . ' | silent! nunmap <buffer> <C-]>'
        \ . ' | silent! nunmap <buffer> <leader>hc'
        \ . ' | silent! nunmap <buffer> <leader>hh'
        \ . ' | silent! nunmap <buffer> <leader>hr'
        \ . ' | silent! nunmap <buffer> <leader>fr')
endfunction

function! s:ft_rust() abort
  setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
  " Save and cargo run in Rust buffers.
  inoremap <buffer> <C-s> <Esc>:update<CR>:! cargo run<CR>
  call s:undo_ftplugin('rust', 'setlocal tabstop< softtabstop< shiftwidth< expandtab<'
        \ . ' | silent! iunmap <buffer> <C-s>')
endfunction

function! s:ft_yaml() abort
  setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab autoindent
  setlocal foldmethod=indent foldlevel=99
  " indentkeys is set in vim/after/indent/yaml.vim: the YAML indent script
  " sets it after this handler has run.
  call s:undo_ftplugin('yaml',
        \ 'setlocal tabstop< softtabstop< shiftwidth< expandtab< autoindent< foldmethod< foldlevel<')
endfunction

augroup dotfiles_ftplugin
  autocmd!
  autocmd FileType * call s:apply_ftplugins()
augroup END

" Commands {{{1
" Thin public entry points; implementations load from vim/autoload/ on first
" use. They are defined before .vim.custom so project overrides can use them.

" Git review {{{2
" Public Git review API, including the entry point used by gitmr.
let g:git_review_left = get(g:, 'git_review_left', '')
let g:git_review_right = get(g:, 'git_review_right', '')

function! ReviewGitGutter(base) abort
  return gitreview#gutter(a:base)
endfunction

function! GitReview(...) abort
  return call('gitreview#open', a:000)
endfunction

function! GitQfDiff() abort
  return gitreview#qf_diff()
endfunction

function! GitQfReviewCommit() abort
  return gitreview#qf_commit()
endfunction

command! -nargs=? Review
      \ call ReviewGitGutter(empty(<q-args>) ? 'origin/main' : <q-args>)

command! ReviewLast
      \ let g:gitgutter_diff_base = 'HEAD^' |
      \ GitGutterAll |
      \ GitGutterQuickFix |
      \ copen

command! ReviewEnd
      \ let g:gitgutter_diff_base = '' |
      \ GitGutterAll |
      \ cclose

command! -nargs=+ GitReview call GitReview(<f-args>)

" GitLab MR selector; reuses GitReview and the quickfix gd/gc mappings above.
if exists(':GitMRs') == 2
  delcommand GitMRs
endif
command! -nargs=? -complete=customlist,gitmr#complete MR call gitmr#open(<q-args>)

" Markdown preview {{{2
function! Glow() abort
  return glow#open()
endfunction

command! Glow call Glow()

" Navigation {{{2
function! Tabs() abort
  return navigation#tabs()
endfunction

function! Today() abort
  return navigation#today()
endfunction

command! Tabs call Tabs()
command! Today call Today()

" Ruby tools {{{2
function! OpenRubyAPI() abort
  return rubytools#api()
endfunction

function! OpenCorrespondingSpec() abort
  return rubytools#spec()
endfunction

command! OpenSpec call OpenCorrespondingSpec()

" Project override {{{1
" Keep the existing per-project override, after personal preferences.
if filereadable('.vim.custom')
  source .vim.custom
endif

" vim: foldmethod=marker
