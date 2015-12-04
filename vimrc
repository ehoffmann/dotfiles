set nocompatible               " be iMproved
filetype on                    " fix git commit message error on leopard
filetype off                   " required!

" case insensitive search
set ignorecase
set rtp+=~/.vim/bundle/vundle/
call vundle#begin()

" let Vundle manage Vundle
" required!
Plugin 'gmarik/vundle'

Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails.git'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'kien/ctrlp.vim'
Plugin 'kchmck/vim-coffee-script'
Plugin 'lunaru/vim-less'
Plugin 'wavded/vim-stylus'
Plugin 'digitaltoad/vim-jade'
Plugin 'vim-scripts/applescript.vim'
Plugin 'ehoffmann/smarty-syntax'
Plugin 'fatih/vim-go'
Plugin 'rust-lang/rust.vim'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'honza/vim-snippets'
Plugin 'garbas/vim-snipmate'
Plugin 'mileszs/ack.vim'
call vundle#end()

filetype plugin indent on     " required!

set number
set ruler
syntax on
set encoding=utf-8

"------------------------------------------------------------------------------
" Whitespace
"------------------------------------------------------------------------------
set nowrap                        " don't wrap lines
set tabstop=2                     " a tab is two spaces
set shiftwidth=2                  " an autoindent (with <<) is two spaces
set expandtab                     " use spaces, not tabs
set backspace=indent,eol,start    " backspace through everything in insert mode
"set iskeyword-=_                  " jump stop on underscore.

"------------------------------------------------------------------------------
" Color
"------------------------------------------------------------------------------

colorscheme molokai
" Better comments for molokai theme
:hi Comment guifg=#708090
" Highlight 81 and onwardd
let &colorcolumn=join(range(81,999),",")
highlight ColorColumn ctermbg=235 guibg=#2c2d27

"------------------------------------------------------------------------------
" Mapping
"------------------------------------------------------------------------------

let mapleader = ","
nmap <silent> <leader>nt :NERDTreeToggle<CR>
" require and call debugger
nmap <leader>id Orequire 'ruby-debug'; debugger<Esc>
" Ack vim shortcut
nmap <leader>t :Ack<SPACE>-i<SPACE>''<LEFT>
" Save current buffer
imap <C-s> <ESC>:update<CR>
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
:runtime macros/matchit.vim

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
autocmd Filetype php setlocal ts=4 sts=4 sw=4

"------------------------------------------------------------------------------
" misc
"------------------------------------------------------------------------------

" Disable error bell
set noeb vb t_vb=
" CtrlP will not index tmp and co
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/Cache/*
" Show end line space
":highlight ExtraWhitespace ctermbg=red guibg=red
":match ExtraWhitespace /\s\+$/
" highlight tabs and trailing spaces
set list listchars=tab:>-,trail:-
highlight SpecialKey term=standout ctermbg=yellow guibg=yellow
" Sane Ignore For ctrlp
let g:ctrlp_custom_ignore = { 'dir': 'node_modules$\|_site\|dist$\|\.git$\|log\|tmp$',
      \ 'file': '\.exe$\|\.so$\|\.dat$' }
let g:ack_default_options = " -s -H --nocolor --nogroup --column --ignore-dir=dist
      \ --ignore-dir=Dev --ignore-dir=systemeold --ignore-dir=Cache"
" NerdTree on mvim
if has("gui_running")
  autocmd VimEnter * NERDTreeToggle
endif
" Ctags
set tags=./tags;
" Allow per project config
if filereadable(".vim.custom")
  so .vim.custom
endif
" Search for visually selected text
vnoremap // y/<C-R>"<CR>

"------------------------------------------------------------------------------
" GO, GOLANG "
"------------------------------------------------------------------------------

au BufNewFile,BufRead *.go set filetype=go
" no tab display
autocmd BufnewFile,BufRead *.go set nolist


"------------------------------------------------------------------------------
" RUST, rust
"------------------------------------------------------------------------------
"
" Save and cargo run
"au BufNewFile,BufRead *.rs imap <C-s> <ESC>:update<CR>:! cargo run
autocmd Filetype rust imap <C-s> <ESC>:update<CR>:! cargo run<CR>
