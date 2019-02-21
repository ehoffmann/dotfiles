set nocompatible " be iMproved
filetype on      " fix git commit message error on leopard
filetype off     " required!

set rtp+=~/.vim/bundle/Vundle.vim/

call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'digitaltoad/vim-jade'
Plugin 'ehoffmann/smarty-syntax'
"Plugin 'fatih/vim-go'
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
Plugin 'tpope/vim-rhubarb'
Plugin 'tpope/vim-rails.git'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-abolish'
Plugin 'tpope/vim-haml'
Plugin 'vim-ruby/vim-ruby'
Plugin 'vim-scripts/applescript.vim'
Plugin 'wavded/vim-stylus'
Plugin 'altercation/vim-colors-solarized'
Plugin 'morhetz/gruvbox'
Plugin 'vim-airline/vim-airline'
Plugin 'jamessan/vim-gnupg'
" Navigate seamlessly between vim and tmux splits
Plugin 'christoomey/vim-tmux-navigator'
" Simplifies the transition between multiline and single-line code
Plugin 'andrewradev/splitjoin.vim'
" Toggle ruby block with <Leader>b
Plugin 'jgdavey/vim-blockle'

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
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
" Tmux background bug
set t_ut=

set background=dark
let g:gruvbox_italic=1
colorscheme gruvbox
" Better comments for molokai theme
":hi Comment guifg=#708090

" Highlight col 101 and onward
let &colorcolumn=join(range(101,6999),",")
"highlight ColorColumn ctermbg=0 guibg=#2c2d27
"highlight ColorColumn ctermbg=24 guibg=#2c2d27
let g:gruvbox_number_column='bg2'
let g:gruvbox_color_column='bg3'

" highlight tabs and trailing spaces
set list listchars=tab:>-,trail:-
highlight SpecialKey term=standout ctermbg=black guibg=yellow

" Keyword highlighting bonus
au BufWinEnter * let w:m1=matchadd('Error', 'BROKEN\|WTF', -1)
au BufWinEnter * let w:m1=matchadd('Todo', 'HACK\|BUG\|REVIEW\|FIXME\|TODO\|NOTE', -1)
au BufWinEnter * let w:m1=matchadd('Special', 'DONE', -1)

"------------------------------------------------------------------------------
" Mapping
"------------------------------------------------------------------------------
let mapleader = ","

nmap <silent> <leader>nt :NERDTreeToggle<CR>

" Ack vim shortcut
nmap <leader>t :Ack<SPACE>-i<SPACE>''<LEFT>

" Fugitive
nnoremap <leader>gs :Gstatus<CR>

" Save time
nmap <SPACE> :

" Clean dirty file
nnoremap <F10> :retab<CR>:%s/\s*$//<CR>

" F11 switch to cp1252 encoding
nnoremap <F11> :e ++enc=cp1252<CR>

" F12 switch to UTF-8 encoding
nnoremap <F12> :e ++enc=utf-8<CR>

" Switch to alternate file
nmap <leader>f :bnext<cr>
nmap <leader>b :bprevious<cr>

" The best shortcut of all time!
inoremap jk <ESC>

" Search for visually selected text
vnoremap // y/<C-R>"<CR>

" Type "visual" yourself!
nnoremap Q <Nop>

" Ruby 1.9 hash
nmap <leader>h :s/:\([^ ]*\)\(\s*\)=>/\1:/g<cr>

" Hash convert "id"=>"1" to id: "1"
nmap <leader>hh :s/["']\(\w*\)["']\(\s*\)=>\s*/\1: /g<cr>

" Swap " for '
nmap <leader>q :s/"/'/g<cr>

" Normalize space between curly (depends on Surround.vim)
nmap <leader>cr cs{}cs}{

" Copy current file path + line num in buffer
"nmap cp :let @" = "https://github.com/teezily/" . expand('%:p:h:t') . "/tree/" . FugitiveHead() . "/" . expand("%") . "#L" . line(".")<cr>
nmap cp :let @" = "https://github.com/teezily/" . systemlist("basename `git rev-parse --show-toplevel`")[0] . "/tree/" . FugitiveHead() . "/" . expand("%") . "#L" . line(".")<cr>

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
let g:ctrlp_custom_ignore = { 'dir': 'node_modules$\|_site\|dist$\|\.git$\|coverage\|log\|tmp$',
      \ 'file': '\.exe$\|\.so$\|\.dat$' }

" Use git file searching
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" Do not display MRU files from other directory (above project root)
let g:ctrlp_mruf_relative = 1

" 'c' - the directory of the current file.
" 'r' - the nearest ancestor that contains one of these directories or files: .git .hg .svn .bzr _darcs
" 'a' - like c, but only if the current working directory outside of CtrlP is not a direct ancestor of the directory of the current file.
"  0 or '' (empty string) - disable this feature.
let g:ctrlp_working_path_mode = 'ra'

"------------------------------------------------------------------------------
" Ack
"------------------------------------------------------------------------------
let g:ack_default_options = " -s -H --nocolor --nogroup --column --ignore-dir=dist
      \ --ignore-dir=Cache --ignore-dir=log --ignore-dir=tmp --ignore-dir=coverage
      \ --ignore-dir=doc --ignore-file=is:tags"

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
" Rails-vim
"------------------------------------------------------------------------------
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
      \  "spec/requests/*/update_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/update_published_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \  "spec/requests/*/delete_spec.rb": {
      \    "alternate": "app/controllers/{}_controller.rb",
      \  },
      \}

"------------------------------------------------------------------------------
" vim-airline
"------------------------------------------------------------------------------
let g:airline_section_a = ''
let g:airline_section_b = ''

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
set path+=lib/**

" Global ignore
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/Cache/*

set clipboard=unnamed
