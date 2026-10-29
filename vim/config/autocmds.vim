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
