set nocompatible " be iMproved
filetype on      " fix git commit message error on leopard
filetype off     " required!

set rtp+=~/.vim/bundle/Vundle.vim/

call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'digitaltoad/vim-jade'
Plugin 'ehoffmann/smarty-syntax'
Plugin 'fatih/vim-go'
Plugin 'garbas/vim-snipmate'
Plugin 'godlygeek/tabular'
Plugin 'honza/vim-snippets'
Plugin 'kchmck/vim-coffee-script'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'lunaru/vim-less'
Plugin 'mileszs/ack.vim'
Plugin 'rust-lang/rust.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'tomtom/tlib_vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails.git'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'
Plugin 'vim-ruby/vim-ruby'
Plugin 'vim-scripts/applescript.vim'
Plugin 'wavded/vim-stylus'
call vundle#end()

filetype plugin indent on     " required!

set number
set ruler
syntax on
set encoding=utf-8
:runtime macros/matchit.vim

"------------------------------------------------------------------------------
" Whitespace
"------------------------------------------------------------------------------
set nowrap                        " don't wrap lines
set tabstop=2                     " a tab is two spaces
set shiftwidth=2                  " an autoindent (with <<) is two spaces
set expandtab                     " use spaces, not tabs
set backspace=indent,eol,start    " backspace through everything in insert mode

"------------------------------------------------------------------------------
" Color
"------------------------------------------------------------------------------
colorscheme molokai

" Better comments for molokai theme
:hi Comment guifg=#708090

" Highlight 81 and onwardd
let &colorcolumn=join(range(81,999),",")
highlight ColorColumn ctermbg=235 guibg=#2c2d27

" highlight tabs and trailing spaces
set list listchars=tab:>-,trail:-
highlight SpecialKey term=standout ctermbg=yellow guibg=yellow

" Keyword highlighting bonus
au BufWinEnter * let w:m1=matchadd('Error', 'BROKEN\|WTF', -1)
au BufWinEnter * let w:m1=matchadd('Todo', 'HACK\|BUG\|REVIEW\|FIXME\|TODO\|NOTE', -1)
au BufWinEnter * let w:m1=matchadd('Special', 'DONE', -1)

"------------------------------------------------------------------------------
" Mapping
"------------------------------------------------------------------------------
let mapleader = ","

nmap <silent> <leader>nt :NERDTreeToggle<CR>

" require and call debugger
nmap <leader>id Obinding.pry<Esc>

" Ack vim shortcut
nmap <leader>t :Ack<SPACE>-i<SPACE>''<LEFT>

" Save time
nmap <SPACE> :

" Clean dirty file
nnoremap <F10> :retab<CR>:%s/\s*$//<CR>

" Press F11 to switch to cp1252 encoding
nnoremap <F11> :e ++enc=cp1252<CR>

" Press F12 to switch to UTF-8 encoding
nnoremap <F12> :e ++enc=utf-8<CR>

" Switch to alternate file
nmap <leader>f :bnext<cr>
nmap <leader>b :bprevious<cr>

" The best shortcup of all time!
inoremap jk <ESC>

" Search for visually selected text
vnoremap // y/<C-R>"<CR>

" Type "visual" yourself !!!
nnoremap Q <Nop>

"------------------------------------------------------------------------------
" Navigation
"------------------------------------------------------------------------------
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"------------------------------------------------------------------------------
" File mapping
"------------------------------------------------------------------------------
au BufNewFile,BufRead *.md set filetype=html
au BufRead,BufNewFile *.tpl set filetype=smarty.html
au BufNewFile,BufRead Guardfile set filetype=ruby
au BufNewFile,BufRead *.styl set filetype=stylus

"------------------------------------------------------------------------------
" Per filetype config
"------------------------------------------------------------------------------
autocmd Filetype html setlocal ts=2 sts=2 sw=2
autocmd Filetype rust setlocal ts=2 sts=2 sw=2
autocmd Filetype ruby setlocal ts=2 sts=2 sw=2
autocmd Filetype javascript setlocal ts=4 sts=4 sw=4

"------------------------------------------------------------------------------
" ctrlp
"------------------------------------------------------------------------------
" Start in mixed mode
let g:ctrlp_cmd = 'CtrlPMixed'

" Search by filename only by default
let g:ctrlp_by_filename = 1

" Sane Ignore
let g:ctrlp_custom_ignore = { 'dir': 'node_modules$\|_site\|dist$\|\.git$\|log\|tmp$',
      \ 'file': '\.exe$\|\.so$\|\.dat$' }

"------------------------------------------------------------------------------
" Ack
"------------------------------------------------------------------------------
let g:ack_default_options = " -s -H --nocolor --nogroup --column --ignore-dir=dist
      \ --ignore-dir=Cache --ignore-dir=log --ignore-dir=tmp
      \ --ignore-file=is:tags"

"------------------------------------------------------------------------------
" NerdTree on mvim
"------------------------------------------------------------------------------
if has("gui_running")
  autocmd VimEnter * NERDTreeToggle
endif

"------------------------------------------------------------------------------
" Ctags
"------------------------------------------------------------------------------
set tags=./tags;

"------------------------------------------------------------------------------
" GO
"------------------------------------------------------------------------------
au BufNewFile,BufRead *.go set filetype=go
" no tab display
autocmd BufnewFile,BufRead *.go set nolist

"------------------------------------------------------------------------------
" Rust
"------------------------------------------------------------------------------
" Save and cargo run
autocmd Filetype rust imap <C-s> <ESC>:update<CR>:! cargo run<CR>

"------------------------------------------------------------------------------
" misc
"------------------------------------------------------------------------------
" case insensitive search
set ignorecase

" Disable error bell
set noeb vb t_vb=

" Allow per project config
if filereadable(".vim.custom")
  so .vim.custom
endif

" Rails project gf goodness
set path+=./app/services;

" Global ignore
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/Cache/*
