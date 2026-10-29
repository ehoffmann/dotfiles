function! navigation#tabs() abort
  let tabs = map(range(1, tabpagenr('$')), {_, n ->
        \ printf('%d	%s',
        \   n,
        \   fnamemodify(
        \     bufname(tabpagebuflist(n)[tabpagewinnr(n) - 1]),
        \     ':.'
        \   )
        \ )
        \ })

  call fzf#run({
        \ 'source': tabs,
        \ 'sink': {line ->
        \   execute('tabnext ' . matchstr(line, '^\d\+'))
        \ }
        \ })
endfunction

function! navigation#today() abort
    let l:dir = "~/work/@daily"
    let l:file = strftime("%Y-%m-%d") . ".md"
    let l:path = l:dir . "/" . l:file
    execute "edit " . fnameescape(l:path)
endfunction
