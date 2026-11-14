" Review annotations from .review/context.json; loaded on first use.
"
" The file sits at the root of the Git repository:
"   {"base": "<sha>", "head": "<sha>",
"    "annotations": [{"path": "app/models/user.rb", "start": 10, "end": 24,
"      "symbol": "User#save", "kind": "method", "summary": "...",
"      "change": "...", "risks": ["...", "..."]}]}
" Paths are relative to the repository root; line ranges are inclusive.

" Virtual text after the line needs Vim 9; older versions use signs, below
" GitGutter's priority so changed-line signs stay visible.
let s:virtual_text = has('textprop') && has('patch-9.1.0')

function! s:error(message) abort
  echohl ErrorMsg
  echomsg 'ReviewContext: ' . a:message
  echohl None
endfunction

function! s:report(result) abort
  if a:result.error
    call s:error(a:result.message)
  else
    echo 'ReviewContext: ' . a:result.message
  endif
endfunction

" A JSON string as popup lines; any other value is ignored.
function! s:text(value) abort
  return type(a:value) == v:t_string ? split(a:value, "\n") : []
endfunction

function! s:valid(item) abort
  return type(a:item) == v:t_dict
        \ && type(get(a:item, 'path', 0)) == v:t_string
        \ && type(get(a:item, 'start', '')) == v:t_number
        \ && type(get(a:item, 'end', '')) == v:t_number
endfunction

function! s:risks(item) abort
  let l:risks = get(a:item, 'risks', [])
  return type(l:risks) == v:t_list
        \ ? filter(copy(l:risks), 'type(v:val) == v:t_string') : []
endfunction

function! s:title(item) abort
  let l:symbol = s:text(get(a:item, 'symbol', ''))
  let l:title = empty(l:symbol) ? 'Review' : l:symbol[0]
  let l:kind = s:text(get(a:item, 'kind', ''))
  return empty(l:kind) ? l:title : l:title . ' (' . l:kind[0] . ')'
endfunction

" Load the review context of the repository containing directory a:dir.
" Return {'root', 'source', 'data', 'annotations'} with only well-formed
" annotations, or {'message', 'error'} when there is none.
function! s:load(dir) abort
  let l:root = systemlist('git -C ' . shellescape(a:dir) . ' rev-parse --show-toplevel')
  if v:shell_error || empty(l:root)
    return {'message': 'not a Git repository', 'error': 0}
  endif
  " Git reports the real path of the root; callers resolve file symlinks too.
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

  return {'root': l:root, 'source': l:source, 'data': l:data,
        \ 'annotations': filter(copy(l:annotations), 's:valid(v:val)')}
endfunction

" The context and repository-relative path of a:file, or an error result.
function! s:context_for(file) abort
  if empty(a:file) || !filereadable(a:file)
    return {'message': 'no file', 'error': 0}
  endif
  let l:file = resolve(fnamemodify(a:file, ':p'))
  let l:context = s:load(fnamemodify(l:file, ':h'))
  if has_key(l:context, 'message')
    return l:context
  endif
  let l:prefix = l:context.root . '/'
  if stridx(l:file, l:prefix) != 0
    return {'message': 'file outside the repository', 'error': 0}
  endif
  let l:context.file = l:file
  let l:context.path = strpart(l:file, strlen(l:prefix))
  return l:context
endfunction

" Reasons why the line ranges may no longer match the code.
function! s:stale_warnings(context, modified) abort
  let l:warnings = []
  let l:head = get(a:context.data, 'head', '')
  if type(l:head) == v:t_string && !empty(l:head)
    let l:current = systemlist('git -C ' . shellescape(a:context.root)
          \ . ' rev-parse HEAD')
    if v:shell_error || empty(l:current) || stridx(l:current[0], l:head) != 0
      call add(l:warnings, '! HEAD moved since this review was generated')
    endif
  endif
  if getftime(a:context.file) > getftime(a:context.source)
    call add(l:warnings, '! File changed after this review was generated')
  endif
  if a:modified
    call add(l:warnings, '! Unsaved changes in this buffer')
  endif
  return empty(l:warnings) ? [] : l:warnings + ['Line ranges may be stale.', '']
endfunction

function! s:section(lines, title, body) abort
  if empty(a:body)
    return
  endif
  call extend(a:lines, [a:title] + a:body + [''])
endfunction

" Return {'lines': [...]} for the most specific annotation covering line
" a:lnum of a:file, or {'message': ..., 'error': 0 or 1} when there is none.
" Pass a true third argument when the buffer has unsaved changes.
function! reviewcontext#annotation(file, lnum, ...) abort
  let l:context = s:context_for(a:file)
  if has_key(l:context, 'message')
    return l:context
  endif

  " The narrowest range covering the line wins.
  let l:best = {}
  for l:item in l:context.annotations
    if l:item.path !=# l:context.path || a:lnum < l:item.start || a:lnum > l:item.end
      continue
    endif
    if empty(l:best) || l:item.end - l:item.start < l:best.end - l:best.start
      let l:best = l:item
    endif
  endfor
  if empty(l:best)
    return {'message': 'no annotation at cursor', 'error': 0}
  endif

  let l:lines = [s:title(l:best), repeat('─', 45), '']
  call extend(l:lines, s:stale_warnings(l:context, get(a:000, 0, 0)))
  call s:section(l:lines, 'DESCRIPTION', s:text(get(l:best, 'summary', '')))
  call s:section(l:lines, 'CHANGE', s:text(get(l:best, 'change', '')))
  call s:section(l:lines, 'RISKS', map(s:risks(l:best), '"- " . v:val'))
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
    call s:report(l:result)
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

function! s:compare(a, b) abort
  if a:a.path !=# a:b.path
    return a:a.path <# a:b.path ? -1 : 1
  endif
  " Enclosing ranges come before the ranges they contain.
  return a:a.start != a:b.start ? a:a.start - a:b.start : a:b.end - a:a.end
endfunction

" Put every annotation of the current repository in the location list.
function! reviewcontext#list() abort
  let l:context = empty(expand('%:p')) ? s:load(getcwd())
        \ : s:load(fnamemodify(resolve(expand('%:p')), ':h'))
  if has_key(l:context, 'message')
    call s:report(l:context)
    return
  endif
  if empty(l:context.annotations)
    echo 'ReviewContext: no annotations'
    return
  endif

  let l:items = []
  for l:item in sort(copy(l:context.annotations), function('s:compare'))
    let l:text = s:title(l:item)
    let l:risks = len(s:risks(l:item))
    if l:risks
      let l:text .= printf(' [%d risk%s]', l:risks, l:risks == 1 ? '' : 's')
    endif
    let l:summary = s:text(get(l:item, 'summary', ''))
    if !empty(l:summary)
      let l:text .= ': ' . l:summary[0]
    endif
    call add(l:items, {'filename': l:context.root . '/' . l:item.path,
          \ 'lnum': l:item.start, 'text': l:text})
  endfor
  call setloclist(0, [], ' ', {'title': 'Review context', 'items': l:items})
  lopen
endfunction

function! s:clear_marks(bufnr) abort
  if s:virtual_text && !empty(prop_type_get('reviewcontext'))
    call prop_remove({'type': 'reviewcontext', 'bufnr': a:bufnr, 'all': 1})
  endif
  if exists('*sign_unplace')
    call sign_unplace('reviewcontext', {'buffer': a:bufnr})
  endif
endfunction

" Mark the first line of each annotation in buffer a:bufnr, after the text or
" in the sign column. b:review_context_mtime records the context it used.
function! reviewcontext#marks(bufnr) abort
  call s:clear_marks(a:bufnr)
  let l:context = s:context_for(fnamemodify(bufname(a:bufnr), ':p'))
  call setbufvar(a:bufnr, 'review_context_mtime',
        \ has_key(l:context, 'source') ? getftime(l:context.source) : -1)
  if !get(g:, 'review_context_marks', 1) || has_key(l:context, 'message')
    return
  endif

  " Annotations starting on the same line share one mark.
  let l:marks = {}
  let l:last = getbufinfo(a:bufnr)[0].linecount
  for l:item in l:context.annotations
    if l:item.path ==# l:context.path && l:item.start >= 1 && l:item.start <= l:last
      let l:marks[l:item.start] = get(l:marks, l:item.start, 0) + len(s:risks(l:item))
    endif
  endfor

  " Restore the link after a colorscheme clears it; Special may not exist yet.
  highlight default link ReviewContextMark Special
  let l:signs = !s:virtual_text || get(g:, 'review_context_signs', 0)
  if l:signs
    call sign_define('ReviewContext', {'text': '»', 'texthl': 'ReviewContextMark'})
  elseif empty(prop_type_get('reviewcontext'))
    call prop_type_add('reviewcontext', {'highlight': 'ReviewContextMark'})
  endif
  for [l:lnum, l:risks] in items(l:marks)
    if l:signs
      call sign_place(0, 'reviewcontext', 'ReviewContext', a:bufnr,
            \ {'lnum': str2nr(l:lnum), 'priority': 5})
    else
      call prop_add(str2nr(l:lnum), 0, {'type': 'reviewcontext', 'bufnr': a:bufnr,
            \ 'text_align': 'after', 'text': l:risks
            \   ? printf('  ◆ %d risk%s', l:risks, l:risks == 1 ? '' : 's')
            \   : '  ◆ review'})
    endif
  endfor
endfunction

" Turn the marks on or off in every loaded file buffer.
function! reviewcontext#toggle_marks() abort
  let g:review_context_marks = !get(g:, 'review_context_marks', 1)
  for l:buffer in getbufinfo({'bufloaded': 1})
    if empty(getbufvar(l:buffer.bufnr, '&buftype'))
      call reviewcontext#marks(l:buffer.bufnr)
    endif
  endfor
  echo 'ReviewContext marks: ' . (g:review_context_marks ? 'on' : 'off')
endfunction
