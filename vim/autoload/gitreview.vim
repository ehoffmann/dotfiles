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
" that merge base. :GitReview origin/main...HEAD reviews the committed versions.
function! gitreview#files(base) abort
  let l:base = trim(system('git merge-base HEAD ' . shellescape(a:base)))
  if v:shell_error || empty(l:base)
    echohl ErrorMsg
    echomsg 'ReviewFiles: could not find the merge base with ' . a:base
    echohl None
    return
  endif
  " The review takes over GitGutter's base, which :ReviewCommits resets.
  call s:gutter_base(l:base)
  call gitreview#open(l:base)
  let l:id = getqflist({'id': 0}).id
  if has_key(s:reviews, l:id)
    let s:reviews[l:id].branch = l:base
    call s:refresh(l:id)
  endif
endfunction

function! s:gutter_base(base) abort
  if get(g:, 'gitgutter_diff_base', '') ==# a:base
    return
  endif
  let g:gitgutter_diff_base = a:base
  if exists(':GitGutterAll') == 2
    GitGutterAll
  endif
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
" tree, such as :ReviewFiles, it also shows GitGutter's signs against the
" review's base, moves to the first hunk, and previews it. Range reviews open
" Fugitive blobs, which GitGutter does not sign, so <CR> only opens them.
function! gitreview#qf_open() abort
  let l:loclist = get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
  if !l:loclist && has_key(s:commit_lists, getqflist({'id': 0}).id)
    call s:open_step(getqflist({'id': 0}).id, line('.'))
    return
  endif
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
  if has_key(s:commit_lists, getqflist({'id': 0}).id)
    call s:open_step(getqflist({'id': 0}).id, line('.'))
    return
  endif
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
" .review/reviewed.json at the repository root, with the commits marked in
" :ReviewCommits by patch ID:
"   {"<base commit>": {"<path>": "<blob hash>"}, "commits": {"<patch ID>": 1}}

" Review lists by quickfix list ID: {root, base, head, title[, parent]
" [, branch][, commits, step]}. head is empty when the right side is the work
" tree. branch is the merge base of :ReviewFiles and of the reviews opened
" from :ReviewCommits, whose list ID is commits, and step the patch ID of
" their commit.
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

function! s:write_store(review, store) abort
  call mkdir(fnamemodify(s:store_file(a:review), ':h'), 'p')
  call writefile([json_encode(a:store)], s:store_file(a:review))
endfunction

" Mark or unmark a:paths, with a:hashes, in the review and in the twin
" reviews where the files have the same diff.
function! s:mark(store, review, paths, hashes, on) abort
  for [l:base, l:paths] in [[a:review.base, a:paths]] + s:twins(a:review, a:paths)
    let l:marks = get(a:store, l:base, {})
    for l:path in l:paths
      if a:on
        let l:marks[l:path] = get(a:hashes, l:path, '')
      else
        silent! call remove(l:marks, l:path)
      endif
    endfor
    let a:store[l:base] = l:marks
  endfor
endfunction

" A file changed by a single step of the branch, a commit or the uncommitted
" changes, has the same diff in the branch's review, from the merge base, as
" in that step's review, from the step's parent: [[base, paths]...] of the
" other review.
function! s:twins(review, paths) abort
  let l:branch = get(a:review, 'branch', '')
  if empty(l:branch)
    return []
  endif
  let l:steps = {}
  for l:step in s:steps(a:review.root, l:branch)
    for l:path in keys(l:step.files)
      let l:steps[l:path] = add(get(l:steps, l:path, []), l:step)
    endfor
  endfor
  let l:twins = {}
  for l:path in a:paths
    let l:touching = get(l:steps, l:path, [])
    if len(l:touching) != 1
      continue
    endif
    let l:step = l:touching[0]
    if a:review.base ==# l:branch && empty(a:review.head)
      let l:base = l:step.parent
    elseif l:step.sha ==# a:review.head && l:step.parent ==# a:review.base
      let l:base = l:branch
    else
      continue
    endif
    if l:base !=# a:review.base
      let l:twins[l:base] = add(get(l:twins, l:base, []), l:path)
    endif
  endfor
  return items(l:twins)
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
  " Lines left to read: the added and deleted lines of files not read.
  let l:stats = s:diff_stats(l:review)
  let l:review.stats = l:stats
  let [l:left, l:total] = [0, 0]
  for l:i in range(len(l:paths))
    let l:size = s:size(get(l:stats, l:paths[l:i], {}))
    let l:total += l:size
    let l:left += l:list.items[l:i].text ==# '✓' ? 0 : l:size
  endfor
  let l:what = {'id': a:id, 'items': l:list.items, 'idx': l:list.idx,
        \ 'title': printf('%s — %d/%d read', l:review.title, l:read, len(l:list.items))
        \ . (l:total ? printf(', %d of %d line%s left', l:left, l:total,
        \   l:total == 1 ? '' : 's') : '')}
  if has('patch-8.2.0959')
    let l:what.quickfixtextfunc = 'gitreview#qftext'
  endif
  call setqflist([], 'r', l:what)
endfunction

" The changes of a review by path: {status, added, deleted[, from]}, where
" status is Git's letter (A, M, D, R...), from the path before a rename, and
" added is -1 for binary files. {} when Git fails.
function! s:diff_stats(review) abort
  let l:output = s:git(a:review.root, '-c core.quotepath=off diff --no-ext-diff'
        \ . ' --no-color --raw --numstat ' . a:review.base
        \ . (empty(a:review.head) ? '' : ' ' . a:review.head) . ' --')
  " Git lists every raw line, then the numstat lines in the same order.
  let l:raw = filter(copy(l:output), 'v:val[0] ==# ":"')
  let l:numstat = filter(copy(l:output), 'v:val[0] !=# ":"')
  let l:stats = {}
  for l:i in range(min([len(l:raw), len(l:numstat)]))
    let l:fields = split(l:raw[l:i], "\t", 1)
    let l:counts = split(l:numstat[l:i], "\t")
    let l:stat = {'status': get(split(l:fields[0]), 4, '?')[0],
          \ 'added': l:counts[0] ==# '-' ? -1 : str2nr(l:counts[0]),
          \ 'deleted': str2nr(get(l:counts, 1, '0'))}
    if len(l:fields) > 2
      let l:stat.from = l:fields[1]
    endif
    let l:stats[l:fields[-1]] = l:stat
  endfor
  return l:stats
endfunction

function! s:size(stat) abort
  return max([0, get(a:stat, 'added', 0)]) + get(a:stat, 'deleted', 0)
endfunction

" Quickfix lines of review lists.
function! gitreview#qftext(info) abort
  if has_key(s:commit_lists, a:info.id)
    return s:commit_lines(a:info.id, a:info.start_idx, a:info.end_idx)
  endif
  return s:file_lines(a:info.id, a:info.start_idx, a:info.end_idx)
endfunction

" Lines of review list items: the read mark, Git's status letter, the added
" and deleted lines, and the path, with the path before a rename.
function! s:file_lines(id, start, end) abort
  let l:review = get(s:reviews, a:id, {})
  let l:items = getqflist({'id': a:id, 'items': 1}).items
  let l:lines = []
  if empty(l:review)
    for l:item in l:items[a:start - 1 : a:end - 1]
      call add(l:lines, (empty(l:item.text) ? ' ' : l:item.text) . ' ' . bufname(l:item.bufnr))
    endfor
    return l:lines
  endif
  let l:stats = get(l:review, 'stats', {})
  let l:paths = map(copy(l:items), 's:path(l:review, v:val)')
  let l:all = map(copy(l:paths), 'get(l:stats, v:val, {})')
  let l:added = max(map(copy(l:all), 'strlen(s:count("+", get(v:val, "added", 0)))'))
  let l:deleted = max(map(copy(l:all), 'strlen(s:count("-", get(v:val, "deleted", 0)))'))
  for l:i in range(a:start - 1, a:end - 1)
    let l:item = l:items[l:i]
    let l:line = (empty(l:item.text) ? ' ' : l:item.text) . ' '
    if !empty(l:stats)
      let l:stat = l:all[l:i]
      let l:line .= get(l:stat, 'status', ' ') . '  '
            \ . s:stat_column(l:stat, l:added, l:deleted) . '  '
    endif
    let l:line .= l:paths[l:i]
    if has_key(get(l:all, l:i, {}), 'from')
      let l:line .= ' ← ' . l:all[l:i].from
    endif
    call add(l:lines, l:line)
  endfor
  return l:lines
endfunction

" '+12' or '-3'; '' for no lines.
function! s:count(sign, n) abort
  return a:n > 0 ? a:sign . a:n : ''
endfunction

" Added and deleted lines, right- and left-aligned on a space in widths
" a:added and a:deleted; bin for binary files.
function! s:stat_column(stat, added, deleted) abort
  let l:width = max([3, a:added + 1 + a:deleted])
  if get(a:stat, 'added', 0) < 0
    return printf('%-*s', l:width, 'bin')
  endif
  return printf('%-*s', l:width, printf('%*s %-*s', a:added,
        \ s:count('+', get(a:stat, 'added', 0)), a:deleted,
        \ s:count('-', get(a:stat, 'deleted', 0))))
endfunction

" The review of the current quickfix list, or {} after reporting why not.
function! s:current_review() abort
  if get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    call s:error('read marks work in the quickfix list of a review')
    return {}
  endif
  let l:id = getqflist({'id': 0}).id
  if !has_key(s:reviews, l:id)
    call s:error('not a review list; start one with :GitReview, :ReviewFiles, or :MR')
    return {}
  endif
  return extend({'id': l:id}, s:reviews[l:id])
endfunction

" Toggle the read mark of items a:first to a:last: mark them all as read,
" or unmark them when they all are read already.
function! gitreview#toggle_read(first, last) abort
  if has_key(s:commit_lists, getqflist({'id': 0}).id)
        \ && !get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    call s:toggle_steps(getqflist({'id': 0}).id, a:first, a:last)
    return
  endif
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
  let l:on = len(l:read) != len(l:paths)
  call s:mark(l:store, l:review, l:paths, l:hashes, l:on)
  " A commit with a file to read again is no longer read as a whole.
  if !l:on && has_key(l:review, 'step')
    silent! call remove(get(l:store, 'commits', {}), l:review.step)
  endif
  call s:write_store(l:review, l:store)

  let l:line = line('.')
  call s:refresh(l:review.id)
  call cursor(l:line, 1)
endfunction

" Switch between all files of the review and those left to read.
function! gitreview#filter_unread() abort
  if has_key(s:commit_lists, getqflist({'id': 0}).id)
        \ && !get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
    call s:filter_steps(getqflist({'id': 0}).id)
    return
  endif
  let l:review = s:current_review()
  if empty(l:review)
    return
  endif
  if has_key(l:review, 'parent')
    if s:goto_list(l:review.parent, 'the full review list')
      call s:refresh(l:review.parent)
    endif
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

" Make the list a:id current, moving in the quickfix history; report when
" Vim no longer keeps it, as a:name.
function! s:goto_list(id, name) abort
  let l:nr = getqflist({'nr': 0}).nr
  let l:target = getqflist({'id': a:id, 'nr': 0}).nr
  if !l:target
    call s:error(a:name . ' is no longer available')
    return 0
  endif
  if l:target != l:nr
    execute 'silent' (l:nr > l:target ? (l:nr - l:target) . 'colder' : (l:target - l:nr) . 'cnewer')
  endif
  return 1
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
  if has_key(s:commit_lists, a:id)
    let l:shown = s:commit_lines(a:id, 1, len(l:items))
    return map(range(len(l:items)),
          \ '(v:val + 1) . "\t" . l:shown[v:val] . "\t" . l:items[v:val].module')
  endif
  let l:shown = empty(l:review) ? [] : s:file_lines(a:id, 1, len(l:items))
  for l:i in range(len(l:items))
    let l:item = l:items[l:i]
    if empty(l:review)
      let l:path = fnamemodify(bufname(l:item.bufnr), ':.')
      let l:text = l:path . (l:item.lnum ? ':' . l:item.lnum : '')
            \ . (empty(l:item.text) ? '' : ': ' . trim(l:item.text))
    else
      let l:path = s:path(l:review, l:item)
      let l:text = l:shown[l:i]
    endif
    call add(l:lines, (l:i + 1) . "\t" . substitute(l:text, "\t", ' ', 'g') . "\t" . l:path)
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
  if has_key(s:commit_lists, a:id)
    call s:keep_steps(a:id, l:kept, l:suffix)
    return
  endif
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
  if has_key(s:commit_lists, a:id)
    call s:open_step(a:id, l:index)
  elseif has_key(s:reviews, a:id)
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
  let l:review = get(s:reviews, l:id, get(s:commit_lists, l:id, {}))
  if !empty(l:review)
    " Preview the file's diff in the review, or the commit, colored like the
    " Git pager; the uncommitted changes have no commit.
    let l:git = 'git -C ' . shellescape(l:review.root)
    let l:diff = has_key(s:commit_lists, l:id)
          \ ? '{ [ -n {3} ] && ' . l:git . ' show --color=always --stat --patch {3}'
          \   . ' || ' . l:git . ' diff --color=always --stat --patch HEAD; }'
          \ : l:git . ' diff --color=always ' . l:review.base
          \   . (empty(l:review.head) ? '' : ' ' . l:review.head) . ' -- {3}'
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

" Commits
" :ReviewCommits lists the commits of the branch from its merge base, oldest
" first, then the uncommitted changes. <CR> lists the files of a commit as a
" review of that commit, from its first parent, and - returns to the
" commits. x marks commits and all their files as read; a commit is read
" when all its files are, and shows how many are otherwise. Marks follow the
" commit's patch ID, so they survive a rebase that keeps its diff.

" Commit lists by quickfix list ID: {root, branch, title, steps[, parent]},
" where steps are the commits by hash, and the uncommitted changes by ''.
let s:commit_lists = get(s:, 'commit_lists', {})

function! gitreview#commits(ref) abort
  let l:root = get(systemlist('git rev-parse --show-toplevel'), 0, '')
  let l:branch = v:shell_error ? ''
        \ : get(s:git(l:root, 'merge-base HEAD ' . shellescape(a:ref)), 0, '')
  if empty(l:branch)
    echohl ErrorMsg
    echomsg 'ReviewCommits: could not find the merge base with ' . a:ref
    echohl None
    return
  endif
  " Commit reviews compare commits, which GitGutter does not sign.
  call s:gutter_base('')
  let l:steps = s:steps(l:root, l:branch)
  if empty(l:steps)
    echo 'ReviewCommits: nothing to review since ' . a:ref
    return
  endif
  let l:title = ':ReviewCommits ' . a:ref
  call setqflist([], ' ', {'title': l:title,
        \ 'items': map(copy(l:steps), '{"module": v:val.sha, "text": ""}')})
  let l:id = getqflist({'id': 0}).id
  let s:commit_lists[l:id] = {'root': l:root, 'branch': l:branch, 'title': l:title}
  call s:refresh_commits(l:id)
  copen
endfunction

" The steps of the branch: its commits, oldest first, then the uncommitted
" changes, as {sha, parent, date, author, subject, files: {path: blob
" hash}, added, deleted}, with the author date in local time and the
" numbers of added and deleted lines. A merge commit's files are those
" changed from its first parent; '' stands for a deleted file.
function! s:steps(root, branch) abort
  let l:steps = []
  for l:line in s:git(a:root, '-c core.quotepath=off log --reverse --no-color'
        \ . ' --no-abbrev --no-ext-diff --diff-merges=first-parent --raw --numstat'
        \ . ' --date=' . shellescape('format-local:%Y-%m-%d %H:%M')
        \ . ' --format=' . shellescape('%x01%H%x09%P%x09%ad%x09%an%x09%s')
        \ . ' ' . a:branch . '..HEAD')
    if l:line[0] ==# "\x01"
      let l:fields = split(l:line[1:], "\t", 1)
      call add(l:steps, {'sha': l:fields[0], 'parent': matchstr(l:fields[1], '^\x\+'),
            \ 'date': get(l:fields, 2, ''), 'author': get(l:fields, 3, ''),
            \ 'subject': join(l:fields[4:], "\t"), 'files': {}, 'added': 0, 'deleted': 0})
    elseif empty(l:steps)
      continue
    elseif l:line =~# '^[0-9-]\+\t[0-9-]\+\t'
      call s:add_counts(l:steps[-1], l:line)
    elseif l:line[0] ==# ':'
      let l:fields = split(l:line, "\t")
      let l:hash = get(split(l:fields[0]), 3, '')
      let l:steps[-1].files[l:fields[-1]] = l:hash =~# '^0*$' ? '' : l:hash
    endif
  endfor
  let l:paths = s:git(a:root, '-c core.quotepath=off diff --no-ext-diff --name-only HEAD --')
  if !empty(l:paths)
    let l:hashes = s:hashes({'root': a:root, 'head': ''}, l:paths)
    let l:files = {}
    for l:path in l:paths
      let l:files[l:path] = get(l:hashes, l:path, '')
    endfor
    let l:step = {'sha': '', 'parent': s:commit(a:root, 'HEAD'), 'date': '',
          \ 'author': '', 'subject': 'Uncommitted changes', 'files': l:files,
          \ 'added': 0, 'deleted': 0}
    for l:line in s:git(a:root, 'diff --no-ext-diff --numstat HEAD --')
      call s:add_counts(l:step, l:line)
    endfor
    call add(l:steps, l:step)
  endif
  return l:steps
endfunction

" Add the counts of a --numstat line to a:step; binary files count none.
function! s:add_counts(step, line) abort
  let l:counts = split(a:line, '\t')
  let a:step.added += str2nr(l:counts[0])
  let a:step.deleted += str2nr(get(l:counts, 1, '0'))
endfunction

" Patch IDs of the commits of the branch, by hash.
function! s:patch_ids(root, branch) abort
  let l:ids = {}
  for l:line in systemlist('git -C ' . shellescape(a:root) . ' log --patch --pretty=medium'
        \ . ' --no-color --no-ext-diff --no-decorate --diff-merges=first-parent '
        \ . a:branch . '..HEAD | git patch-id --stable')
    let l:fields = split(l:line)
    if len(l:fields) == 2
      let l:ids[l:fields[1]] = l:fields[0]
    endif
  endfor
  return l:ids
endfunction

" The mark of a step: ✓ when it or all its files are read, the number of
" read files otherwise.
function! s:step_status(store, step, ids) abort
  let l:marks = get(a:store, a:step.parent, {})
  let l:total = len(a:step.files)
  let l:read = len(filter(items(a:step.files), 'get(l:marks, v:val[0], "-") ==# v:val[1]'))
  if l:total && l:read == l:total || !empty(a:step.sha)
        \ && has_key(get(a:store, 'commits', {}), get(a:ids, a:step.sha, a:step.sha))
    return '✓'
  endif
  return l:read ? l:read . '/' . l:total : ''
endfunction

function! s:refresh_commits(id) abort
  let l:list = s:commit_lists[a:id]
  let l:list.steps = {}
  for l:step in s:steps(l:list.root, l:list.branch)
    let l:list.steps[l:step.sha] = l:step
  endfor
  let l:list.ids = s:patch_ids(l:list.root, l:list.branch)
  let l:store = s:read_store(l:list)
  let l:store = type(l:store) == v:t_dict ? l:store : {}
  let l:qf = getqflist({'id': a:id, 'items': 1, 'idx': 0})
  let l:read = 0
  for l:item in l:qf.items
    " A commit rewritten since the list was made is no longer on the branch.
    let l:step = get(l:list.steps, l:item.module, {})
    let l:item.text = empty(l:step) ? '?' : s:step_status(l:store, l:step, l:list.ids)
    let l:read += l:item.text ==# '✓'
  endfor
  let l:what = {'id': a:id, 'items': l:qf.items, 'idx': l:qf.idx,
        \ 'title': printf('%s — %d/%d read', l:list.title, l:read, len(l:qf.items))}
  if has('patch-8.2.0959')
    let l:what.quickfixtextfunc = 'gitreview#qftext'
  endif
  call setqflist([], 'r', l:what)
endfunction

" Lines of commit list items: the mark, the short hash, the date and time,
" the author, the added and deleted lines, and the subject, in aligned
" columns.
function! s:commit_lines(id, start, end) abort
  let l:list = s:commit_lists[a:id]
  let l:items = getqflist({'id': a:id, 'items': 1}).items
  " Authors take the width of the longest, up to 20 columns.
  let l:width = max(map(copy(l:items),
        \ 'min([20, strdisplaywidth(get(get(l:list.steps, v:val.module, {}), "author", ""))])'))
  let l:steps = map(copy(l:items), 'get(l:list.steps, v:val.module, {})')
  let l:added = max(map(copy(l:steps), 'strlen(s:count("+", get(v:val, "added", 0)))'))
  let l:deleted = max(map(copy(l:steps), 'strlen(s:count("-", get(v:val, "deleted", 0)))'))
  let l:lines = []
  for l:item in l:items[a:start - 1 : a:end - 1]
    let l:step = get(l:list.steps, l:item.module, {})
    let l:mark = empty(l:item.text) ? ' ' : l:item.text
    let l:author = s:column(get(l:step, 'author', ''), l:width)
    let l:columns = empty(l:item.module) ? repeat(' ', 27 + l:width)
          \ : printf('%s %-16s %s  ', l:item.module[:6], get(l:step, 'date', ''), l:author)
    call add(l:lines, s:column(l:mark, 6) . l:columns
          \ . s:stat_column(l:step, l:added, l:deleted) . '  '
          \ . get(l:step, 'subject', 'no longer on the branch'))
  endfor
  return l:lines
endfunction

" a:text in a:width display columns: padded, or cut with an ellipsis.
function! s:column(text, width) abort
  let l:text = a:text
  if strdisplaywidth(l:text) > a:width
    while strdisplaywidth(l:text) > a:width - 1
      let l:text = strcharpart(l:text, 0, strchars(l:text) - 1)
    endwhile
    let l:text = substitute(l:text, '\s\+$', '', '') . '…'
  endif
  return l:text . repeat(' ', a:width - strdisplaywidth(l:text))
endfunction

" List the files of the step at a:index as a review of that step.
function! s:open_step(id, index) abort
  let l:list = s:commit_lists[a:id]
  let l:item = get(getqflist({'id': a:id, 'items': 1}).items, a:index - 1, {})
  let l:step = get(l:list.steps, get(l:item, 'module', '?'), {})
  if empty(l:step)
    call s:error('this commit is no longer on the branch; run :ReviewCommits again')
    return
  endif
  " - returns to this entry.
  call setqflist([], 'a', {'id': a:id, 'idx': a:index})
  if empty(l:step.sha)
    call gitreview#open('HEAD')
  else
    call gitreview#open(l:step.sha . '^', l:step.sha)
  endif
  let l:review = getqflist({'id': 0}).id
  if !has_key(s:reviews, l:review)
    return
  endif
  call extend(s:reviews[l:review], {'branch': l:list.branch, 'commits': a:id,
        \ 'step': get(l:list.ids, l:step.sha, l:step.sha),
        \ 'title': (empty(l:step.sha) ? '' : l:step.sha[:6] . ' ') . l:step.subject})
  call s:refresh(l:review)
  copen
endfunction

" Mark the steps a:first to a:last and all their files as read, or unmark
" them when they all are read already.
function! s:toggle_steps(id, first, last) abort
  let l:list = s:commit_lists[a:id]
  let l:store = s:read_store(l:list)
  if type(l:store) != v:t_dict
    call s:error('invalid JSON in ' . s:store_file(l:list))
    return
  endif
  call s:refresh_commits(a:id)
  let l:items = getqflist({'id': a:id, 'items': 1}).items[a:first - 1 : a:last - 1]
  call filter(l:items, 'has_key(l:list.steps, v:val.module)')
  let l:on = !empty(filter(copy(l:items), 'v:val.text !=# "✓"'))
  let l:commits = get(l:store, 'commits', {})
  for l:item in l:items
    let l:step = l:list.steps[l:item.module]
    if !empty(l:step.sha)
      let l:key = get(l:list.ids, l:step.sha, l:step.sha)
      if l:on
        let l:commits[l:key] = 1
      else
        silent! call remove(l:commits, l:key)
      endif
    endif
    call s:mark(l:store, {'root': l:list.root, 'base': l:step.parent, 'head': l:step.sha,
          \ 'branch': l:list.branch}, keys(l:step.files), l:step.files, l:on)
  endfor
  let l:store.commits = l:commits
  call s:write_store(l:list, l:store)
  let l:line = line('.')
  call s:refresh_commits(a:id)
  call cursor(l:line, 1)
endfunction

" Register a:items of the commit list a:id as a new list.
function! s:keep_steps(id, items, suffix) abort
  let l:list = s:commit_lists[a:id]
  let l:parent = get(l:list, 'parent', a:id)
  let l:title = get(get(s:commit_lists, l:parent, {}), 'title', l:list.title) . a:suffix
  call setqflist([], ' ', {'title': l:title, 'items': a:items})
  let s:commit_lists[getqflist({'id': 0}).id] = extend(copy(l:list),
        \ {'parent': l:parent, 'title': l:title})
  call s:refresh_commits(getqflist({'id': 0}).id)
endfunction

" Switch between all commits and those left to read.
function! s:filter_steps(id) abort
  let l:list = s:commit_lists[a:id]
  if has_key(l:list, 'parent')
    if s:goto_list(l:list.parent, 'the full commit list')
      call s:refresh_commits(l:list.parent)
    endif
    return
  endif
  call s:refresh_commits(a:id)
  let l:items = filter(getqflist({'id': a:id, 'items': 1}).items, 'v:val.text !=# "✓"')
  if empty(l:items)
    echo 'GitReview: every commit is read'
    return
  endif
  call s:keep_steps(a:id, l:items, ' (to read)')
endfunction

" - in the files of a commit returns to the commit list.
function! gitreview#up() abort
  let l:loclist = get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
  let l:review = l:loclist ? {} : get(s:reviews, getqflist({'id': 0}).id, {})
  if !has_key(l:review, 'commits')
    execute 'normal!' v:count1 . '-'
    return
  endif
  if s:goto_list(l:review.commits, 'the commit list')
    call s:refresh_commits(l:review.commits)
  endif
endfunction

" <leader>k on a commit, or in its files, shows its message; elsewhere it
" shows the review context as usual.
function! gitreview#message() abort
  let l:loclist = get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
  let l:id = l:loclist ? 0 : getqflist({'id': 0}).id
  if has_key(s:commit_lists, l:id)
    let l:root = s:commit_lists[l:id].root
    let l:sha = get(get(getqflist({'id': l:id, 'items': 1}).items, line('.') - 1, {}),
          \ 'module', '?')
  elseif has_key(get(s:reviews, l:id, {}), 'commits')
    let l:root = s:reviews[l:id].root
    let l:sha = s:reviews[l:id].head
  else
    ReviewContext
    return
  endif
  if empty(l:sha)
    let l:lines = ['Uncommitted changes', ''] + s:git(l:root, 'diff --stat HEAD --')
  else
    let l:lines = s:git(l:root, 'show --no-color --stat --format=%B ' . shellescape(l:sha))
  endif
  if !has('popupwin') || empty(l:lines)
    return
  endif
  call popup_atcursor(l:lines + ['', 'q / Esc: close'], {'border': [], 'padding': [1, 2, 1, 2],
        \ 'maxwidth': 85, 'maxheight': 25, 'wrap': 1, 'moved': 'any',
        \ 'filter': function('s:popup_filter')})
endfunction

function! s:popup_filter(id, key) abort
  if a:key ==# 'q' || a:key ==# "\<Esc>"
    call popup_close(a:id)
    return 1
  endif
  return 0
endfunction
