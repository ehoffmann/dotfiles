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
