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

"------------------------------------------------------------------------------
" Search
"------------------------------------------------------------------------------
set incsearch
set showmatch
set ignorecase  " ignore case when searching
set smartcase   " override 'ignorecase' if pattern contains uppercase - ignorecase should be set

set tabstop=2                   " a tab is two spaces
set shiftwidth=2                " an autoindent (with <<) is two spaces
set expandtab                   " use spaces, not tabs
set backspace=indent,eol,start  " backspace through everything in insert mode

"------------------------------------------------------------------------------
" Wrap
"------------------------------------------------------------------------------
set wrap                        " wrap lines
set linebreak                   " breaks by word rather than character
set breakindent                 " wrapped line visually indented (same amount as the beginning line)
set showbreak=↪\                " break symbol

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
