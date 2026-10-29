" Solarized (manual install from https://github.com/altercation/vim-colors-solarized/tree/master#option-1-manual-installation
" set background=dark
" let g:solarized_diffmode="high"
" let g:solarized_diffmode="low"
" colorscheme solarized

" Fix issue with spell check and solarized " https://github.com/altercation/vim-colors-solarized/issues/195
set t_Cs=

" Gruvbox
set termguicolors
let g:gruvbox_italic=1
colorscheme gruvbox
set background=dark
" let g:gruvbox_number_column='bg2'
" let g:gruvbox_color_column='bg3'

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
