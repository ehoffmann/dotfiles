" Review annotations from .review/context.json; loaded on first use.
"
" The file sits at the root of the Git repository:
"   {"base": "<sha>", "head": "<sha>",
"    "annotations": [{"path": "app/models/user.rb", "start": 10, "end": 24,
"      "symbol": "User#save", "kind": "method", "summary": "...",
"      "change": "...", "risks": ["...", "..."]}]}
" Paths are relative to the repository root; line ranges are inclusive.

function! s:error(message) abort
  echohl ErrorMsg
  echomsg 'ReviewContext: ' . a:message
  echohl None
endfunction

" A JSON string as popup lines; any other value is ignored.
function! s:text(value) abort
  return type(a:value) == v:t_string ? split(a:value, "\n") : []
endfunction

function! s:section(lines, title, body) abort
  if empty(a:body)
    return
  endif
  call extend(a:lines, [a:title] + a:body + [''])
endfunction

" Reasons why the line ranges may no longer match the code.
function! s:stale_warnings(data, root, source, file, modified) abort
  let l:warnings = []
  let l:head = get(a:data, 'head', '')
  if type(l:head) == v:t_string && !empty(l:head)
    let l:current = systemlist('git -C ' . shellescape(a:root) . ' rev-parse HEAD')
    if v:shell_error || empty(l:current) || stridx(l:current[0], l:head) != 0
      call add(l:warnings, '! HEAD moved since this review was generated')
    endif
  endif
  if getftime(a:file) > getftime(a:source)
    call add(l:warnings, '! File changed after this review was generated')
  endif
  if a:modified
    call add(l:warnings, '! Unsaved changes in this buffer')
  endif
  return empty(l:warnings) ? [] : l:warnings + ['Line ranges may be stale.', '']
endfunction

" Return {'lines': [...]} for the most specific annotation covering line
" a:lnum of a:file, or {'message': ..., 'error': 0 or 1} when there is none.
" Pass a true third argument when the buffer has unsaved changes.
function! reviewcontext#annotation(file, lnum, ...) abort
  if empty(a:file) || !filereadable(a:file)
    return {'message': 'no file', 'error': 0}
  endif

  " Git reports the real path of the root; match it through symlinks.
  let l:file = resolve(fnamemodify(a:file, ':p'))
  let l:root = systemlist('git -C ' . shellescape(fnamemodify(l:file, ':h'))
        \ . ' rev-parse --show-toplevel')
  if v:shell_error || empty(l:root)
    return {'message': 'not a Git repository', 'error': 0}
  endif
  let l:root = resolve(l:root[0])

  let l:source = l:root . '/.review/context.json'
  if !filereadable(l:source)
    return {'message': 'no .review/context.json in ' . fnamemodify(l:root, ':~'),
          \ 'error': 0}
  endif

  try
    let l:data = json_decode(join(readfile(l:source), "\n"))
  catch
    return {'message': 'invalid JSON in ' . l:source, 'error': 1}
  endtry
  let l:annotations = type(l:data) == v:t_dict ? get(l:data, 'annotations', []) : 0
  if type(l:annotations) != v:t_list
    return {'message': 'expected an object with an annotations list in '
          \ . l:source, 'error': 1}
  endif

  let l:prefix = l:root . '/'
  if stridx(l:file, l:prefix) != 0
    return {'message': 'file outside the repository', 'error': 0}
  endif
  let l:path = strpart(l:file, strlen(l:prefix))

  " The narrowest range covering the line wins.
  let l:best = {}
  let l:best_size = -1
  for l:item in l:annotations
    if type(l:item) != v:t_dict || get(l:item, 'path', '') isnot# l:path
      continue
    endif
    let l:start = get(l:item, 'start', 0)
    let l:end = get(l:item, 'end', 0)
    if type(l:start) != v:t_number || type(l:end) != v:t_number
          \ || a:lnum < l:start || a:lnum > l:end
      continue
    endif
    if l:best_size < 0 || l:end - l:start < l:best_size
      let l:best = l:item
      let l:best_size = l:end - l:start
    endif
  endfor

  if empty(l:best)
    return {'message': 'no annotation at cursor', 'error': 0}
  endif

  let l:symbol = s:text(get(l:best, 'symbol', ''))
  let l:title = empty(l:symbol) ? 'Review' : l:symbol[0]
  let l:kind = s:text(get(l:best, 'kind', ''))
  if !empty(l:kind)
    let l:title .= ' (' . l:kind[0] . ')'
  endif
  let l:lines = [l:title, repeat('─', 45), '']
  call extend(l:lines, s:stale_warnings(l:data, l:root, l:source, l:file,
        \ get(a:000, 0, 0)))
  call s:section(l:lines, 'DESCRIPTION', s:text(get(l:best, 'summary', '')))
  call s:section(l:lines, 'CHANGE', s:text(get(l:best, 'change', '')))
  let l:risks = get(l:best, 'risks', [])
  if type(l:risks) == v:t_list
    call s:section(l:lines, 'RISKS', map(filter(copy(l:risks),
          \ 'type(v:val) == v:t_string'), '"- " . v:val'))
  endif
  call add(l:lines, 'q / Esc: close')
  return {'lines': l:lines}
endfunction

function! s:filter(id, key) abort
  if a:key ==# 'q' || a:key ==# "\<Esc>"
    call popup_close(a:id)
    return 1
  endif
  return 0
endfunction

" Show the annotation at the cursor; return the popup ID, or 0.
function! reviewcontext#show() abort
  if !has('popupwin')
    call s:error('requires Vim with +popupwin')
    return 0
  endif

  let l:result = reviewcontext#annotation(expand('%:p'), line('.'), &modified)
  if has_key(l:result, 'message')
    if l:result.error
      call s:error(l:result.message)
    else
      echo 'ReviewContext: ' . l:result.message
    endif
    return 0
  endif

  return popup_atcursor(l:result.lines, {
        \ 'border': [],
        \ 'padding': [1, 2, 1, 2],
        \ 'maxwidth': 85,
        \ 'maxheight': 25,
        \ 'wrap': 1,
        \ 'moved': 'any',
        \ 'filter': function('s:filter'),
        \ })
endfunction
