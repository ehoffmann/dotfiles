" Git review implementation; loaded on first use.

function! gitreview#gutter(base) abort
  let l:base = trim(system(
        \ 'git merge-base HEAD ' . shellescape(a:base)
        \ ))

  if v:shell_error || empty(l:base)
    echoerr 'Could not find merge base with ' . a:base
    return
  endif

  let g:gitgutter_diff_base = l:base
  GitGutterAll
  GitGutterQuickFix
  copen
endfunction

" Review the branch, uncommitted changes included, from its merge base with
" a:base: the quickfix lists work tree files, and gd diffs each one against
" that merge base. A range such as origin/main...HEAD reviews commits instead.
function! gitreview#branch(base) abort
  let l:base = trim(system('git merge-base HEAD ' . shellescape(a:base)))
  if v:shell_error || empty(l:base)
    echohl ErrorMsg
    echomsg 'ReviewBranch: could not find the merge base with ' . a:base
    echohl None
    return
  endif
  call gitreview#open(l:base)
endfunction

function! gitreview#open(...) abort
  let g:git_review_left = a:1
  let g:git_review_right = a:0 >= 2 ? a:2 : ''

  if empty(g:git_review_right)
    execute 'Git difftool --name-only ' . g:git_review_left
  else
    execute 'Git difftool --name-only '
          \ . g:git_review_left . ' '
          \ . g:git_review_right
  endif
  call s:track(g:git_review_left, g:git_review_right)
endfunction

function! gitreview#qf_diff() abort
  let qf_idx = line('.')
  call setqflist([], 'a', {'idx': qf_idx})

  let item = getqflist()[qf_idx - 1]
  let file = bufname(item.bufnr)

  " Reset the window layout.
  only

  if empty(g:git_review_right)
    " Review the current branch or working tree.
    execute 'edit ' . fnameescape(file)
    execute 'Gvdiffsplit ' . g:git_review_left
  else
    " Review history between two commits.
    " Fugitive already supplies the historical buffer path in quickfix.
    execute 'edit ' . fnameescape(file)
    execute 'Gvdiffsplit ' . g:git_review_left
  endif

  wincmd h
  execute 'vertical resize ' . float2nr(&columns * 0.35)

  " Keep quickfix below the diff, on the same entry.
  botright copen
  resize 10
  call cursor(qf_idx, 1)

  " Return to the diff.
  wincmd k
  wincmd l
endfunction

" <CR> in the quickfix list opens the entry as usual. In a review of the work
" tree, such as :ReviewBranch, it also shows GitGutter's signs against the
" review's base, moves to the first hunk, and previews it. Range reviews open
" Fugitive blobs, which GitGutter does not sign, so <CR> only opens them.
function! gitreview#qf_open() abort
  let l:loclist = get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
  let l:review = l:loclist ? {} : get(s:reviews, getqflist({'id': 0}).id, {})
  execute "normal! \<CR>"
  if empty(l:review) || !empty(l:review.head) || &buftype ==# 'quickfix'
        \ || exists(':GitGutterAll') != 2
    return
  endif
  call s:first_hunk(l:review.base)
endfunction

function! s:first_hunk(base) abort
  let l:bufnr = bufnr('')
  let l:moved = get(g:, 'gitgutter_diff_base', '') !=# a:base
  let g:gitgutter_diff_base = a:base
  " Compute the hunks now instead of in a background job; a new base also
  " applies to the other buffers, as with :Review.
  let [l:async, g:gitgutter_async] = [get(g:, 'gitgutter_async', 1), 0]
  try
    if l:moved
      call gitgutter#all(1)
    else
      call gitgutter#process_buffer(l:bufnr, 1)
    endif
  finally
    let g:gitgutter_async = l:async
  endtry
  let l:hunks = gitgutter#hunk#hunks(l:bufnr)
  if empty(l:hunks)
    echo 'GitReview: no changes from ' . a:base[:6]
    return
  endif
  " A deletion at the top of the file starts at line 0.
  execute 'normal!' max([l:hunks[0][2], 1]) . 'Gzv'
  call gitgutter#hunk#preview()
endfunction

function! gitreview#qf_commit() abort
  let item = getqflist()[line('.') - 1]
  let commit = item.module

  if empty(commit)
    echoerr 'No commit on this quickfix entry'
    return
  endif

  execute 'GitReview ' . commit . '^ ' . commit
endfunction

" Read marks
" x in a review quickfix list marks files as read and gr shows only the files
" left to read. A mark records the reviewed version of the file: its blob in
" the right commit, or its work tree content. When the file changes, the mark
" turns to ~ and the file is to read again. Marks persist per merge base in
" .review/reviewed.json at the repository root:
"   {"<base commit>": {"<path>": "<blob hash>"}}

" Review lists by quickfix list ID: {root, base, head, title[, parent]}.
" head is empty when the right side is the work tree.
let s:reviews = get(s:, 'reviews', {})

function! s:error(message) abort
  echohl ErrorMsg
  echomsg 'GitReview: ' . a:message
  echohl None
endfunction

function! s:git(root, args) abort
  let l:output = systemlist('git -C ' . shellescape(a:root) . ' ' . a:args)
  return v:shell_error ? [] : l:output
endfunction

function! s:commit(root, rev) abort
  return get(s:git(a:root, 'rev-parse --verify --quiet '
        \ . shellescape((empty(a:rev) ? 'HEAD' : a:rev) . '^{commit}')), 0, '')
endfunction

" The base and head commits of a review; head is empty for the work tree.
function! s:endpoints(root, left, right) abort
  if !empty(a:right)
    return [s:commit(a:root, a:left), s:commit(a:root, a:right)]
  endif
  let l:range = matchlist(a:left, '^\(.\{-}\)\(\.\.\.\?\)\(.*\)$')
  if empty(l:range)
    return [s:commit(a:root, a:left), '']
  endif
  let l:head = s:commit(a:root, l:range[3])
  if l:range[2] ==# '...'
    let l:left = s:commit(a:root, l:range[1])
    let l:base = empty(l:left) || empty(l:head) ? ''
          \ : get(s:git(a:root, 'merge-base ' . l:left . ' ' . l:head), 0, '')
    return [l:base, l:head]
  endif
  return [s:commit(a:root, l:range[1]), l:head]
endfunction

" Remember the list that :Git difftool just created, and show its marks.
function! s:track(left, right) abort
  let l:list = getqflist({'id': 0, 'title': 1})
  let l:root = get(systemlist('git rev-parse --show-toplevel'), 0, '')
  if !l:list.id || l:list.title !~# 'difftool' || v:shell_error || empty(l:root)
    return
  endif
  let [l:base, l:head] = s:endpoints(l:root, a:left, a:right)
  if empty(l:base) || (!empty(a:right) || a:left =~# '\.\.') && empty(l:head)
    return
  endif
  let s:reviews[l:list.id] = {'root': l:root, 'base': l:base, 'head': l:head,
        \ 'title': l:list.title}
  call s:refresh(l:list.id)
endfunction

" The repository-relative path of a review quickfix item.
function! s:path(review, item) abort
  let l:name = bufname(a:item.bufnr)
  if l:name =~# '^fugitive:'
    return matchstr(l:name, '^fugitive:.\{-}//\x\+/\zs.*')
  endif
  let l:file = resolve(fnamemodify(l:name, ':p'))
  let l:prefix = a:review.root . '/'
  return stridx(l:file, l:prefix) == 0 ? strpart(l:file, strlen(l:prefix)) : l:name
endfunction

" Blob hashes of a:paths in the reviewed version; '' for missing files.
function! s:hashes(review, paths) abort
  let l:hashes = {}
  if empty(a:paths)
    return l:hashes
  endif
  let l:args = join(map(copy(a:paths), 'shellescape(v:val)'))
  if empty(a:review.head)
    let l:present = filter(copy(a:paths), 'filereadable(a:review.root . "/" . v:val)')
    if !empty(l:present)
      let l:output = s:git(a:review.root, 'hash-object -- '
            \ . join(map(copy(l:present), 'shellescape(v:val)')))
      for l:i in range(min([len(l:present), len(l:output)]))
        let l:hashes[l:present[l:i]] = l:output[l:i]
      endfor
    endif
  else
    for l:line in s:git(a:review.root, '-c core.quotepath=off ls-tree -r '
          \ . a:review.head . ' -- ' . l:args)
      let l:fields = matchlist(l:line, '^\S\+ \S\+ \(\x\+\)\t\(.*\)$')
      if !empty(l:fields)
        let l:hashes[l:fields[2]] = l:fields[1]
      endif
    endfor
  endif
  return l:hashes
endfunction

function! s:store_file(review) abort
  return a:review.root . '/.review/reviewed.json'
endfunction

" The stored marks of every review, or v:null when the file is invalid.
function! s:read_store(review) abort
  let l:file = s:store_file(a:review)
  if !filereadable(l:file)
    return {}
  endif
  try
    let l:store = json_decode(join(readfile(l:file), "\n"))
  catch
    return v:null
  endtry
  return type(l:store) == v:t_dict ? l:store : v:null
endfunction

" Set the mark of every item from the stored marks and current hashes.
function! s:refresh(id) abort
  let l:review = s:reviews[a:id]
  let l:list = getqflist({'id': a:id, 'items': 1, 'idx': 0})
  let l:store = s:read_store(l:review)
  let l:marks = type(l:store) == v:t_dict ? get(l:store, l:review.base, {}) : {}
  let l:paths = map(copy(l:list.items), 's:path(l:review, v:val)')
  let l:hashes = s:hashes(l:review, l:paths)
  let l:read = 0
  for l:i in range(len(l:list.items))
    let l:path = l:paths[l:i]
    let l:text = !has_key(l:marks, l:path) ? ''
          \ : l:marks[l:path] ==# get(l:hashes, l:path, '') ? '✓' : '~'
    let l:list.items[l:i].text = l:text
    let l:read += l:text ==# '✓'
  endfor
  let l:what = {'id': a:id, 'items': l:list.items, 'idx': l:list.idx,
        \ 'title': printf('%s — %d/%d read', l:review.title, l:read, len(l:list.items))}
  if has('patch-8.2.0959')
    let l:what.quickfixtextfunc = 'gitreview#qftext'
  endif
  call setqflist([], 'r', l:what)
endfunction

" Quickfix lines of review lists: the mark, then the file path.
function! gitreview#qftext(info) abort
  let l:review = get(s:reviews, a:info.id, {})
  let l:items = getqflist({'id': a:info.id, 'items': 1}).items
  let l:lines = []
  for l:item in l:items[a:info.start_idx - 1 : a:info.end_idx - 1]
    let l:path = empty(l:review) ? bufname(l:item.bufnr) : s:path(l:review, l:item)
    call add(l:lines, (empty(l:item.text) ? ' ' : l:item.text) . ' ' . l:path)
  endfor
  return l:lines
endfunction

" The review of the current quickfix list, or {} after reporting why not.
function! s:current_review() abort
  if get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    call s:error('read marks work in the quickfix list of a review')
    return {}
  endif
  let l:id = getqflist({'id': 0}).id
  if !has_key(s:reviews, l:id)
    call s:error('not a review list; start one with :GitReview, :ReviewBranch, or :MR')
    return {}
  endif
  return extend({'id': l:id}, s:reviews[l:id])
endfunction

" Toggle the read mark of items a:first to a:last: mark them all as read,
" or unmark them when they all are read already.
function! gitreview#toggle_read(first, last) abort
  let l:review = s:current_review()
  if empty(l:review)
    return
  endif
  let l:store = s:read_store(l:review)
  if type(l:store) != v:t_dict
    call s:error('invalid JSON in ' . s:store_file(l:review))
    return
  endif
  let l:items = getqflist({'id': l:review.id, 'items': 1}).items[a:first - 1 : a:last - 1]
  let l:paths = map(l:items, 's:path(l:review, v:val)')
  let l:hashes = s:hashes(l:review, l:paths)
  let l:marks = get(l:store, l:review.base, {})
  let l:read = filter(copy(l:paths),
        \ 'get(l:marks, v:val, "-") ==# get(l:hashes, v:val, "")')
  for l:path in l:paths
    if len(l:read) == len(l:paths)
      silent! call remove(l:marks, l:path)
    else
      let l:marks[l:path] = get(l:hashes, l:path, '')
    endif
  endfor
  let l:store[l:review.base] = l:marks
  call mkdir(fnamemodify(s:store_file(l:review), ':h'), 'p')
  call writefile([json_encode(l:store)], s:store_file(l:review))

  let l:line = line('.')
  call s:refresh(l:review.id)
  call cursor(l:line, 1)
endfunction

" Switch between all files of the review and those left to read.
function! gitreview#filter_unread() abort
  let l:review = s:current_review()
  if empty(l:review)
    return
  endif
  let l:nr = getqflist({'nr': 0}).nr
  if has_key(l:review, 'parent')
    let l:parent = getqflist({'id': l:review.parent, 'nr': 0}).nr
    if !l:parent
      call s:error('the full review list is no longer available')
      return
    endif
    call s:refresh(l:review.parent)
    execute 'silent' (l:nr > l:parent ? (l:nr - l:parent) . 'colder' : (l:parent - l:nr) . 'cnewer')
    return
  endif

  call s:refresh(l:review.id)
  let l:items = filter(getqflist({'id': l:review.id, 'items': 1}).items,
        \ 'v:val.text !=# "✓"')
  if empty(l:items)
    echo 'GitReview: every file is read'
    return
  endif
  call setqflist([], ' ', {'title': l:review.title . ' (to read)', 'items': l:items})
  let l:id = getqflist({'id': 0}).id
  let s:reviews[l:id] = extend(copy(s:reviews[l:review.id]),
        \ {'parent': l:review.id, 'title': l:review.title . ' (to read)'})
  call s:refresh(l:id)
endfunction

" Fuzzy filter
" g/ in the quickfix list opens fzf on its entries, with fzf's extended
" search: 'service !spec' keeps entries matching service but not spec.
" Enter keeps every match as a new list; in a review, that list keeps the
" read marks, and gr returns to the full review. Ctrl-O opens the entry under
" the cursor instead. :ReviewFilter {query} filters without the interface.

" Entries as fzf lines: index, shown text, and path for the preview.
function! s:fzf_lines(id) abort
  let l:review = get(s:reviews, a:id, {})
  let l:items = getqflist({'id': a:id, 'items': 1}).items
  let l:lines = []
  for l:i in range(len(l:items))
    let l:item = l:items[l:i]
    if empty(l:review)
      let l:path = fnamemodify(bufname(l:item.bufnr), ':.')
      let l:shown = l:path . (l:item.lnum ? ':' . l:item.lnum : '')
            \ . (empty(l:item.text) ? '' : ': ' . trim(l:item.text))
    else
      let l:path = s:path(l:review, l:item)
      let l:shown = (empty(l:item.text) ? ' ' : l:item.text) . ' ' . l:path
    endif
    call add(l:lines, (l:i + 1) . "\t" . substitute(l:shown, "\t", ' ', 'g') . "\t" . l:path)
  endfor
  return l:lines
endfunction

" Make a new list of the entries of list a:id at the 1-based a:indices.
function! s:keep(id, indices, query) abort
  let l:items = getqflist({'id': a:id, 'items': 1}).items
  let l:indices = filter(uniq(sort(map(copy(a:indices), 'str2nr(v:val)'), 'n')),
        \ 'v:val >= 1 && v:val <= len(l:items)')
  if empty(l:indices)
    echo 'GitReview: nothing matches ' . a:query
    return
  endif
  let l:kept = map(l:indices, 'l:items[v:val - 1]')
  let l:suffix = ' (filter: ' . a:query . ')'
  let l:review = get(s:reviews, a:id, {})
  if empty(l:review)
    call setqflist([], ' ', {'items': l:kept,
          \ 'title': getqflist({'id': a:id, 'title': 1}).title . l:suffix})
    return
  endif
  " Filters of filters still return to the full review.
  let l:parent = get(l:review, 'parent', a:id)
  let l:title = get(get(s:reviews, l:parent, {}), 'title', l:review.title) . l:suffix
  call setqflist([], ' ', {'title': l:title, 'items': l:kept})
  let l:id = getqflist({'id': 0}).id
  let s:reviews[l:id] = extend(copy(l:review), {'parent': l:parent, 'title': l:title})
  call s:refresh(l:id)
endfunction

" The current quickfix list ID, or 0 after reporting why there is none.
function! s:filterable() abort
  if get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    call s:error('filters work on the quickfix list')
    return 0
  endif
  let l:id = getqflist({'id': 0}).id
  if !l:id || empty(getqflist({'id': l:id, 'items': 1}).items)
    call s:error('the quickfix list is empty')
    return 0
  endif
  return l:id
endfunction

function! gitreview#filter(query) abort
  let l:id = s:filterable()
  if !l:id
    return
  endif
  if !executable('fzf')
    call s:error('ReviewFilter requires fzf')
    return
  endif
  let l:output = systemlist('fzf --no-sort --delimiter=' . shellescape("\t")
        \ . ' --nth=2 --filter=' . shellescape(a:query), s:fzf_lines(l:id))
  " fzf exits with 1 when nothing matches, and with 2 on errors.
  if v:shell_error > 1
    call s:error('fzf failed: ' . join(l:output))
    return
  endif
  call s:keep(l:id, map(l:output, 'matchstr(v:val, "^\\d\\+")'), a:query)
endfunction

function! s:fzf_sink(id, lines) abort
  " --print-query and --expect put the query and the key first.
  if len(a:lines) < 3 || empty(a:lines[0]) && a:lines[1] !=# 'ctrl-o'
    return
  endif
  let l:indices = map(a:lines[2:], 'matchstr(v:val, "^\\d\\+")')
  if a:lines[1] !=# 'ctrl-o'
    call s:keep(a:id, l:indices, a:lines[0])
    return
  endif
  let l:index = str2nr(l:indices[0])
  if has_key(s:reviews, a:id)
    copen
    call cursor(l:index, 1)
    call gitreview#qf_diff()
  else
    execute l:index . 'cc'
  endif
endfunction

function! gitreview#fzf() abort
  let l:id = s:filterable()
  if !l:id
    return
  endif
  " Only the shown text is searched; the index and the path stay hidden.
  let l:options = ['--multi', '--delimiter', "\t", '--with-nth', '2',
        \ '--print-query', '--expect', 'ctrl-o', '--bind', 'enter:select-all+accept',
        \ '--prompt', 'Filter> ']
  let l:header = 'Enter: keep matches · C-o: open'
  let l:review = get(s:reviews, l:id, {})
  if !empty(l:review)
    " Preview the file's diff in the review, colored like the Git pager.
    let l:diff = 'git -C ' . shellescape(l:review.root) . ' diff --color=always '
          \ . l:review.base . (empty(l:review.head) ? '' : ' ' . l:review.head) . ' -- {3}'
    call extend(l:options, ['--preview', l:diff . (executable('diffr') ? ' | diffr' : ''),
          \ '--preview-window', 'right,60%,wrap', '--bind', 'ctrl-/:toggle-preview'])
    let l:header .= ' · C-/: preview'
  endif
  call extend(l:options, ['--header', l:header])
  let l:spec = {'source': s:fzf_lines(l:id), 'sink*': function('s:fzf_sink', [l:id]),
        \ 'options': l:options}
  try
    call fzf#run(exists('*fzf#wrap') ? fzf#wrap('review-filter', l:spec) : l:spec)
  catch /^Vim\%((\a\+)\)\=:E117:/
    call s:error('g/ requires fzf.vim')
  endtry
endfunction
