" Markdown terminal preview; loaded on first use.

let s:mark    = 'GLOWMARKZQX'
let s:rowmark = '◆'

function! s:MarkRows(lines) abort
  let l:fence = 0
  for l:i in range(len(a:lines))
    let l:l = a:lines[l:i]
    if l:l =~# '^\s*\(```\|\~\~\~\)'
      let l:fence = !l:fence
      continue
    endif
    if l:fence || l:l !~# '^\s*|' || l:l =~# '^\s*|[-:| ]\+$'
      continue
    endif
    if get(a:lines, l:i + 1, '') =~# '^\s*|[-:| ]\+$'
      continue          " Header row.
    endif
    let a:lines[l:i] = substitute(l:l, '^\(\s*|\s*\)', '\1' . s:rowmark . ' ', '')
  endfor
  return a:lines
endfunction

function! s:MarkedLines() abort
  let l:lines = s:MarkRows(getline(1, '$'))
  let l:i = line('.') - 1

  let l:skip = '^\s*\%(\%(-\{3,}\|\*\{3,}\|=\{3,}\|_\{3,}\)\s*$\|```\|\~\~\~\|$\)'
  let l:skip .= '\|^\s*|[-:| ]\+$'
  while l:i >= 0 && l:lines[l:i] =~# l:skip
    let l:i -= 1
  endwhile
  if l:i < 0
    return l:lines
  endif

  if l:lines[l:i] =~# '^\s*|.*|\s*$'
    let l:lines[l:i] = substitute(l:lines[l:i], '\s*|\s*$', ' ' . s:mark . ' |', '')
  else
    let l:lines[l:i] .= ' ' . s:mark
  endif
  return l:lines
endfunction

function! s:Jump() abort
  highlight GlowMark ctermfg=212 guifg=#ff79c6 cterm=bold gui=bold
  call matchadd('GlowMark', s:rowmark, 5)

  call cursor(1, 1)
  if search(s:mark, 'cW')
    call cursor(line('.'), 1)      " Keep nowrap from shifting the view toward the marker.
    call matchadd('Conceal', ' \?' . s:mark, 10, -1, {'conceal': ''})
    setlocal conceallevel=2 concealcursor=nvic
  endif
  normal! zt
endfunction

function! s:Top() abort
  let l:buf = s:buf
  if !bufexists(l:buf)
    autocmd! GlowTop
    return
  endif
  if term_getstatus(l:buf) =~# 'running'
    return
  endif
  autocmd! GlowTop
  let l:win = bufwinid(l:buf)
  if l:win != -1
    call win_execute(l:win, 'call s:Jump()')
  endif
endfunction

function! glow#open() abort
  let l:file = tempname() . '.md'
  call writefile(s:MarkedLines(), l:file)

  tabnew
  setlocal nonumber norelativenumber signcolumn=no foldcolumn=0

  let s:buf = term_start(['glow', '-s', 'dracula', '-w', string(winwidth(0)), l:file], {
        \ 'curwin': 1,
        \ 'exit_cb': {-> delete(l:file)},
        \ })

  setlocal nowrap nospell colorcolumn=
  setlocal list listchars=precedes:«,extends:»
  setlocal bufhidden=wipe scrolloff=3

  nnoremap <buffer> q :tabclose!<CR>
  tnoremap <buffer> q <C-\><C-N>:tabclose!<CR>

  augroup GlowTop
    autocmd!
    autocmd SafeState * call s:Top()
  augroup END
endfunction
