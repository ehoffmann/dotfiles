set nocompatible " be iMproved
filetype off     " required!

set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

" Interpret a file by function and cache file automatically, used by
" other plugin
Plugin 'MarcWeber/vim-addon-mw-utils'

" Snippets
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'

" Vim script for text filtering and alignment
Plugin 'godlygeek/tabular'

" CoffeeScript support
Plugin 'kchmck/vim-coffee-script'

" Fuzzy file finder
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'

" LessCSS Syntax support
Plugin 'lunaru/vim-less'

" Plugin for the Perl module / CLI script 'ack'
Plugin 'mileszs/ack.vim'

" Comment
Plugin 'tomtom/tcomment_vim'

" File tree
Plugin 'scrooloose/nerdtree'

" Some utility functions for VIM
Plugin 'tomtom/tlib_vim'

" Ruby support
Plugin 'vim-ruby/vim-ruby'

" Required for 'nelstrom/vim-textobj-rubyblock'
Plugin 'kana/vim-textobj-user'

" New text objects, al 'a line' and il 'inner line'
Plugin 'kana/vim-textobj-line'

" Ruby text object
Plugin 'nelstrom/vim-textobj-rubyblock'

" Git wrapper
Plugin 'tpope/vim-fugitive'

" GitHub extension for fugitive.vim, GBrowse, hub, completion in commit msg
Plugin 'tpope/vim-rhubarb'

" Dot repeat at plugin level
Plugin 'tpope/vim-repeat'

" Quoting/parenthesizing made simple
Plugin 'tpope/vim-surround'

" Easily search for, substitute, and abbreviate multiple variants of a word
Plugin 'tpope/vim-abolish'

" Runtime files for Haml, Sass, and SCSS
Plugin 'tpope/vim-haml'

" Rails
Plugin 'tpope/vim-rails.git'

" Retro groove color scheme for Vim
" Plugin 'morhetz/gruvbox'

" Transparent editing of gpg encrypted files
Plugin 'jamessan/vim-gnupg'

" Navigate seamlessly between vim and tmux splits
Plugin 'christoomey/vim-tmux-navigator'

" Simplifies the transition between multiline and single-line code
Plugin 'andrewradev/splitjoin.vim'

" Toggle ruby block with <Leader>b
Plugin 'jgdavey/vim-blockle'

" Perform an interactive diff on two blocks of text
Plugin 'AndrewRadev/linediff.vim'

" Speed up Vim by updating folds only when called-for
Plugin 'Konfekt/FastFold'

" A git diff in the gutter (sign column), stages/undoes hunks and partial hunks.
Plugin 'airblade/vim-gitgutter'

call vundle#end()

filetype plugin indent on " required!

set number
set ruler
syntax on
set encoding=utf-8
:runtime macros/matchit.vim
set ignorecase                  " case insensitive search
set noeb vb t_vb=               " Disable error bell

"------------------------------------------------------------------------------
" Search
"------------------------------------------------------------------------------
set incsearch " highlight matched string.

" hlsearch only when cmd
augroup vimrc-incsearch-highlight
  autocmd!
  autocmd CmdlineEnter /,\? :set hlsearch
  autocmd CmdlineLeave /,\? :set nohlsearch
augroup END

"------------------------------------------------------------------------------
" Whitespace
"------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
" Color / Scheme
"------------------------------------------------------------------------------

" Solarized (manual install from https://github.com/altercation/vim-colors-solarized/tree/master#option-1-manual-installation
set background=dark
" let g:solarized_diffmode="high"
" let g:solarized_diffmode="low"
colorscheme solarized

" Fix issue with spell check and solarized " https://github.com/altercation/vim-colors-solarized/issues/195
set t_Cs=

" Gruvbox
" set background=light
" colorscheme gruvbox
" let g:gruvbox_italic=1
" let g:gruvbox_number_column='bg2'
" let g:gruvbox_color_column='bg3'

" Highlight col 101 and onward
" let &colorcolumn=join(range(101,6999),",")

" Highlight tabs and trailing spaces
set list listchars=tab:→\ ,nbsp:␣,trail:•,precedes:«,extends:»

" Keyword highlighting bonus
au BufWinEnter * let w:m1=matchadd('Error', 'BROKEN\|WTF', -1)
au BufWinEnter * let w:m1=matchadd('Todo', 'HACK\|BUG\|REVIEW\|FIXME\|TODO\|NOTE', -1)
au BufWinEnter * let w:m1=matchadd('Special', 'DONE', -1)

"------------------------------------------------------------------------------
" Mapping
"------------------------------------------------------------------------------
nmap <silent> <leader>nt :NERDTreeToggle<CR>

" After pasting, type gp to select the pasted text in visual mode. This is
" similar to the standard gv which you can type to select the last
" visually-selected text.
nnoremap gp `[v`]

" Save time
nmap <SPACE> :

" F11 switch to cp1252 encoding
nnoremap <F7> :e ++enc=cp1252<CR>

" F12 switch to UTF-8 encoding
nnoremap <F8> :e ++enc=utf-8<CR>

" Clean dirty file
nnoremap <F9> :retab<CR>:%s/\s*$//<CR>

" Search for visually selected text
vnoremap // y/<C-R>"<CR>

" Type "visual" yourself!
nnoremap Q <Nop>

" Ruby 1.9 hash: convert from `':test' => 123` to `test: 123`,
" memo: Colon
nmap <leader>hc :s/:\([^ ]*\)\(\s*\)=>/\1:/g<cr>

" Rocket to Hash convert "id"=>"1" to id: "1",
" memo: Hash
nmap <leader>hh :s/["']\(\w*\)["']\(\s*\)=>\s*/\1: /g<cr>

" Hash to Rocket id: "1" to "id" => "1"
" memo: Rocket
nmap <leader>hr :s/\(\w*\):\s*/'\1' => /g<cr>

" Swap quotes " for '
nmap <leader>q :s/"/'/g<cr>

" Normalize space between curly (depends on Surround.vim)
nmap <leader>cr cs{}cs}{

" Mark task as done
nmap <leader>x :s/\[ \]/[X]/<cr>

" Copy current file path and line number into system clipboard. Use gF then.
nnoremap <Leader>cp :let @+ = expand('%:p') . ':' . line('.')<CR>

"------------------------------------------------------------------------------
" Split navigation shortcut (same as tmux)
"------------------------------------------------------------------------------
" Aleady set by Plugin 'christoomey/vim-tmux-navigator'
" nnoremap <C-J> <C-W><C-J>
" nnoremap <C-K> <C-W><C-K>
" nnoremap <C-L> <C-W><C-L>
" nnoremap <C-H> <C-W><C-H>

"------------------------------------------------------------------------------
" File mapping
"------------------------------------------------------------------------------
au BufRead,BufNewFile *.tpl set filetype=smarty.html
au BufNewFile,BufRead Guardfile set filetype=ruby
au BufNewFile,BufRead *.styl set filetype=stylus

"------------------------------------------------------------------------------
" Per filetype config
"------------------------------------------------------------------------------
autocmd Filetype html setlocal ts=2 sts=2 sw=2
autocmd Filetype rust setlocal ts=2 sts=2 sw=2
autocmd Filetype ruby setlocal ts=2 sts=2 sw=2
autocmd Filetype javascript setlocal ts=2 sts=2 sw=2

"------------------------------------------------------------------------------
" netrw
"------------------------------------------------------------------------------
" Disable default gx
let g:netrw_nogx = 1
" Remap gx to open any URL under cursor in the browser
nmap gx yiW:!xdg-open "<C-r>"" > /dev/null<CR><CR>

"------------------------------------------------------------------------------
" FZF
"------------------------------------------------------------------------------
command! -bang -nargs=? -complete=dir Files
      \ call fzf#vim#files(<q-args>, {'options': ['--info=inline', '--preview', 'less {}']}, <bang>0)
nmap <C-P> :Files<CR>

"------------------------------------------------------------------------------
" Ack / AG / Grep
"------------------------------------------------------------------------------
" Use ag instead of ack
" let g:ackprg = 'ag --vimgrep --hidden --ignore .git'
let g:ackprg = 'rg --vimgrep'

nmap <leader>a :Ack!<SPACE>''<LEFT>

" Visual selection to Ack
vnoremap <Leader>a "ay:Ack! <C-r>=fnameescape(@a)<CR><CR>

"------------------------------------------------------------------------------
" diff
"------------------------------------------------------------------------------
" Ignore white space in vimdiff, Gdiffsplit...
set diffopt+=iwhite

"------------------------------------------------------------------------------
" Ctags
"------------------------------------------------------------------------------
set tags=./tags;

"------------------------------------------------------------------------------
" gitgutter
"------------------------------------------------------------------------------
set updatetime=750
highlight! link SignColumn LineNr

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
" Projections:
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

"------------------------------------------------------------------------------
" Ruby
"------------------------------------------------------------------------------
" Fold/unfold all def in Ruby file
let ruby_foldable_groups = 'def do'
nmap <leader>ff :set foldmethod=syntax<CR>
nmap <leader>fu :set foldmethod=manual<CR>zR<CR>

" Syntax
let ruby_space_errors = 1
let ruby_operators        = 1
let ruby_pseudo_operators = 1
let ruby_line_continuation_error = 1
let ruby_global_variable_error   = 1
let ruby_spellcheck_strings = 1

" Search ruby online doc for the word under cursor
function! OpenRubyAPI()
    let word = expand('<cword>')
    let cmd = "ruby -v | sed -E 's/^ruby\\s([0-9]+\\.[0-9]+).*/\\1/'"
    let ruby_version = trim(system(cmd))
    let url = 'https://rubyapi.org/' . ruby_version . '/o/s?q=' . word
    execute '!xdg-open ' . shellescape(url)
endfunction
nnoremap <leader>rd :call OpenRubyAPI()<CR>

"------------------------------------------------------------------------------
" Create/open spec file in Rails project
"------------------------------------------------------------------------------
function! OpenCorrespondingSpec()
  " Get the current file's path
  let l:current_file_path = expand('%:p')

  " Transform the path to the corresponding spec path
  let l:spec_file_path = substitute(l:current_file_path, 'app/', 'spec/', '')
  let l:spec_file_path = substitute(l:spec_file_path, '.rb', '_spec.rb', '')

  " Create the directory for the spec file if it doesn't exist
  execute '!mkdir -p ' . fnamemodify(l:spec_file_path, ':h')

  " Open the spec file
  execute 'edit ' . l:spec_file_path
endfunction

" Command
command! OpenSpec :call OpenCorrespondingSpec()

" Mapping
" nnoremap <leader>s :call OpenCorrespondingSpec()<cr>

"------------------------------------------------------------------------------
" Markdown (tpope vim-markdown, embedeed in vim)
" https://github.com/tpope/vim-markdown
"------------------------------------------------------------------------------
let g:markdown_fenced_languages = ['ruby', 'js=javascript', 'json', 'yaml', 'bash=sh']

"------------------------------------------------------------------------------
" misc
"------------------------------------------------------------------------------
"
" Allow per project config
if filereadable(".vim.custom")
  so .vim.custom
endif

" Rails project gf goodness
set path+=lib/**

" Global ignore
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/Cache/*

" Use clipboard. https://stackoverflow.com/a/30691754/1876625
set clipboard^=unnamed,unnamedplus

" Snipmate deprecate v0
let g:snipMate = { 'snippet_version' : 1 }
