function! s:nesting() abort
  let nesting = []
  let lnum = line('.')
  let ind = indent(lnum)
  for l in range(lnum - 1, 1, -1)
    let m = matchlist(getline(l), '^\s*\%(module\|class\)\s\+\([A-Z][A-Za-z0-9_:]*\)')
    if !empty(m) && indent(l) < ind
      call extend(nesting, split(m[1], '::'), 0)
      let ind = indent(l)
      if ind == 0 | break | endif
    endif
  endfor
  return nesting
endfunction

function! s:jump_to(t) abort
  let from = [bufnr()] + getcurpos()[1:]
  call settagstack(win_getid(), {'items': [{'tagname': a:t.name, 'from': from}]}, 't')
  if expand('%:p') !=# fnamemodify(a:t.filename, ':p')
    execute 'edit' fnameescape(a:t.filename)
  endif
  if has_key(a:t, 'line')
    execute a:t.line
  else
    let save = &magic | set nomagic
    execute a:t.cmd
    let &magic = save
  endif
  normal! zv
endfunction

function! rubytag#jump() abort
  let word = exists('*RubyCursorIdentifier') ? RubyCursorIdentifier() : expand('<cword>')
  let parts = split(word, '::')
  let name = parts[-1]
  let prefix = parts[:-2]
  let tags = taglist('^' . escape(name, '\.*$^~[]') . '$')

  if !empty(tags)
    let nest = word =~# '^::' ? [] : s:nesting()
    for n in range(len(nest), 0, -1)
      let want = join((n == 0 ? [] : nest[: n - 1]) + prefix, '.')
      for t in tags
        if get(t, 'module', get(t, 'class', '')) ==# want
          call s:jump_to(t)
          return
        endif
      endfor
    endfor
  endif

  execute "normal! g\<C-]>"
endfunction
