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

" The working-tree path of a buffer name. Fugitive buffers, such as the blobs
" opened by :GitReview and :MR, are named fugitive://<git dir>//<rev>/<path>.
function! s:real(name) abort
  return a:name =~# '^fugitive:' && exists('*FugitiveReal') ? FugitiveReal(a:name) : a:name
endfunction

" Whether buffer a:bufnr shows another version than its working-tree file,
" whose line numbers the annotations describe.
function! s:differs(bufnr) abort
  let l:name = bufname(a:bufnr)
  let l:real = s:real(l:name)
  return l:real !=# l:name && filereadable(l:real)
        \ && getbufline(a:bufnr, 1, '$') !=# readfile(l:real)
endfunction

" The directory whose repository the current buffer belongs to.
function! s:current_dir() abort
  let l:file = s:real(expand('%:p'))
  return empty(l:file) ? getcwd() : fnamemodify(resolve(l:file), ':h')
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
  let l:file = s:real(a:file)
  if empty(l:file) || !filereadable(l:file)
    return {'message': 'no file', 'error': 0}
  endif
  let l:file = resolve(fnamemodify(l:file, ':p'))
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

" Whether HEAD differs from the full or abbreviated head of the context.
function! s:head_moved(context) abort
  let l:head = get(a:context.data, 'head', '')
  if type(l:head) != v:t_string || empty(l:head)
    return 0
  endif
  let l:current = systemlist('git -C ' . shellescape(a:context.root) . ' rev-parse HEAD')
  return v:shell_error || empty(l:current) || stridx(l:current[0], l:head) != 0
endfunction

" Reasons why the line ranges may no longer match the code.
function! s:stale_warnings(context, modified, differs) abort
  let l:warnings = []
  if s:head_moved(a:context)
    call add(l:warnings, '! HEAD moved since this review was generated')
  endif
  if getftime(a:context.file) > getftime(a:context.source)
    call add(l:warnings, '! File changed after this review was generated')
  endif
  if a:modified
    call add(l:warnings, '! Unsaved changes in this buffer')
  endif
  if a:differs
    call add(l:warnings, '! This version differs from the working-tree file')
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
" Pass a true third argument when the buffer has unsaved changes, and a true
" fourth one when it shows another version than the working-tree file.
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
  call extend(l:lines, s:stale_warnings(l:context, get(a:000, 0, 0), get(a:000, 1, 0)))
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

  let l:result = reviewcontext#annotation(expand('%:p'), line('.'), &modified,
        \ s:differs(bufnr('%')))
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
  let l:context = s:load(s:current_dir())
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
  let l:context = s:context_for(bufname(a:bufnr))
  call setbufvar(a:bufnr, 'review_context_mtime',
        \ has_key(l:context, 'source') ? getftime(l:context.source) : -1)
  " Marks of another version would land on the wrong lines.
  if !get(g:, 'review_context_marks', 1) || has_key(l:context, 'message')
        \ || s:differs(a:bufnr)
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

" Review summary
" The optional "summary" object of the context describes the whole change:
"   {"intent": "...", "goals": [...], "non_goals": [...],
"    "contract": [{"text": "...", "status": "changed", "ref": {"path": ..., "start": ...}}],
"    "reading_order": [{"path": "...", "start": 1, "why": "..."}],
"    "tests": [...], "risks": [...], "questions": [...]}
" Contract statuses are "breaking", "changed", or "unchanged".

let s:status_rank = {'breaking': 0, 'changed': 1, 'unchanged': 2}

function! s:strings(value) abort
  return type(a:value) == v:t_list
        \ ? filter(copy(a:value), 'type(v:val) == v:t_string') : []
endfunction

" A {path, start} reference, or {} when a:value is not a valid one.
function! s:ref(value) abort
  return type(a:value) == v:t_dict
        \ && type(get(a:value, 'path', 0)) == v:t_string
        \ && type(get(a:value, 'start', '')) == v:t_number
        \ ? {'path': a:value.path, 'start': a:value.start} : {}
endfunction

function! s:compare_status(a, b) abort
  return get(s:status_rank, a:a.status, 3) - get(s:status_rank, a:b.status, 3)
endfunction

" Return {'lines': [...], 'refs': {lnum: {path, start}}} for the summary.
function! s:summary_lines(context) abort
  let l:summary = a:context.data.summary
  let l:lines = ['# Review summary', '']
  let l:refs = {}

  let l:range = []
  for l:key in ['base', 'head']
    let l:sha = get(a:context.data, l:key, '')
    if type(l:sha) == v:t_string && !empty(l:sha)
      call add(l:range, printf('%s `%s`', l:key, l:sha[:6]))
    endif
  endfor
  if !empty(l:range)
    call extend(l:lines, [join(l:range, ' → '), ''])
  endif

  let l:warnings = s:head_moved(a:context)
        \ ? ['> ! HEAD moved since this review was generated'] : []
  let l:paths = map(copy(a:context.annotations), 'v:val.path')
  for l:item in type(get(l:summary, 'reading_order', 0)) == v:t_list
        \ ? l:summary.reading_order : []
    call add(l:paths, get(s:ref(l:item), 'path', ''))
  endfor
  let l:changed = len(filter(uniq(sort(filter(l:paths, '!empty(v:val)'))),
        \ 'getftime(a:context.root . "/" . v:val) > getftime(a:context.source)'))
  if l:changed
    call add(l:warnings, printf('> ! %d file%s changed after this review was generated',
          \ l:changed, l:changed == 1 ? '' : 's'))
  endif
  if !empty(l:warnings)
    call extend(l:lines, l:warnings + ['> Line references may be stale.', ''])
  endif

  let l:intent = s:text(get(l:summary, 'intent', ''))
  if !empty(l:intent)
    call extend(l:lines, ['## Intent'] + l:intent + [''])
  endif
  for [l:key, l:title] in [['goals', 'Goals'], ['non_goals', 'Non-goals']]
    call s:section(l:lines, '## ' . l:title,
          \ map(s:strings(get(l:summary, l:key, [])), '"- " . v:val'))
  endfor

  " Contract: breaking changes first, then changes, then explicit guarantees.
  let l:contract = []
  for l:item in type(get(l:summary, 'contract', 0)) == v:t_list ? l:summary.contract : []
    if type(l:item) == v:t_dict && type(get(l:item, 'text', 0)) == v:t_string
      let l:status = get(l:item, 'status', '')
      call add(l:contract, {'text': l:item.text, 'ref': s:ref(get(l:item, 'ref', 0)),
            \ 'status': type(l:status) == v:t_string ? l:status : ''})
    endif
  endfor
  if !empty(l:contract)
    call add(l:lines, '## Contract')
    for l:item in sort(l:contract, function('s:compare_status'))
      let l:line = '- ' . (empty(l:item.status) ? '' : '[' . l:item.status . '] ')
            \ . split(l:item.text, "\n")[0]
      if !empty(l:item.ref)
        let l:line .= printf(' (%s:%d)', l:item.ref.path, l:item.ref.start)
        let l:refs[len(l:lines) + 1] = l:item.ref
      endif
      call add(l:lines, l:line)
    endfor
    call add(l:lines, '')
  endif

  let l:steps = []
  for l:item in type(get(l:summary, 'reading_order', 0)) == v:t_list
        \ ? l:summary.reading_order : []
    if !empty(s:ref(l:item))
      call add(l:steps, l:item)
    endif
  endfor
  if !empty(l:steps)
    call add(l:lines, '## Reading order')
    for l:i in range(len(l:steps))
      let l:why = s:text(get(l:steps[l:i], 'why', ''))
      let l:refs[len(l:lines) + 1] = s:ref(l:steps[l:i])
      call add(l:lines, printf('%d. %s:%d%s', l:i + 1, l:steps[l:i].path,
            \ l:steps[l:i].start, empty(l:why) ? '' : ' — ' . l:why[0]))
    endfor
    call add(l:lines, '')
  endif

  for [l:key, l:title] in [['tests', 'Tests'], ['risks', 'Risks'], ['questions', 'Questions']]
    call s:section(l:lines, '## ' . l:title,
          \ map(s:strings(get(l:summary, l:key, [])), '"- " . v:val'))
  endfor
  call add(l:lines, '<CR> on a file reference opens it beside this summary; q closes.')
  return {'lines': l:lines, 'refs': l:refs}
endfunction

" Open the summary of the current repository in a new tab.
function! reviewcontext#summary() abort
  let l:context = s:load(s:current_dir())
  if has_key(l:context, 'message')
    call s:report(l:context)
    return
  endif
  if !has_key(l:context.data, 'summary')
    echo 'ReviewContext: no summary in ' . l:context.source
    return
  endif
  if type(l:context.data.summary) != v:t_dict
    call s:error('expected a summary object in ' . l:context.source)
    return
  endif
  let l:result = s:summary_lines(l:context)

  " Keep a single summary buffer.
  for l:buffer in getbufinfo()
    if has_key(l:buffer.variables, 'review_summary_refs')
      execute 'bwipeout' l:buffer.bufnr
    endif
  endfor
  tabnew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent file Review\ summary
  call setline(1, l:result.lines)
  setlocal filetype=markdown nomodifiable readonly
  let b:review_summary_root = l:context.root
  let b:review_summary_refs = l:result.refs
  nnoremap <buffer> <silent> <CR> :call reviewcontext#summary_jump()<CR>
  " Wiping the buffer also closes its window, and its tab when others remain.
  nnoremap <buffer> <silent> q :bwipeout<CR>
endfunction

" Open the reference on the cursor line in the window beside the summary.
function! reviewcontext#summary_jump() abort
  let l:ref = get(b:review_summary_refs, line('.'), {})
  if empty(l:ref)
    echo 'ReviewContext: no file reference on this line'
    return
  endif
  let l:file = b:review_summary_root . '/' . l:ref.path
  let l:summary = winnr()
  if winnr('l') != l:summary
    wincmd l
  else
    rightbelow vsplit
    execute l:summary . 'wincmd w'
    execute 'vertical resize ' . float2nr(&columns * 0.35)
    wincmd l
  endif
  execute 'edit ' . fnameescape(l:file)
  call cursor(l:ref.start, 1)
  normal! zvzz
endfunction
