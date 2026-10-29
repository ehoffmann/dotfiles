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
