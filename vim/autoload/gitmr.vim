" GitLab MR selection for classic Vim. Network operations use jobs; reviews
" are delegated to the existing GitReview and Fugitive's Gclog commands.
if exists('g:autoloaded_gitmr')
  finish
endif
let g:autoloaded_gitmr = 1

function! s:git(repo, args) abort
  let cmd = ['git', '-C', a:repo] + a:args
  let lines = systemlist(join(map(cmd, 'shellescape(v:val)'), ' ') . ' 2>&1')
  return {'code': v:shell_error, 'lines': lines}
endfunction

function! s:sha(value) abort
  return type(a:value) == v:t_string && a:value =~# '^\x\{40}\%(\x\{24}\)\?$'
        \ ? a:value : ''
endfunction

function! s:require(repo, refs) abort
  let missing = []
  for ref in a:refs
    if s:git(a:repo, ['cat-file', '-e', ref . '^{commit}']).code
      call add(missing, ref)
    endif
  endfor
  if !empty(missing)
    throw 'gitmr:missing:' . join(missing, ',')
  endif
endfunction

function! s:parents(repo, sha) abort
  " Read the object itself: git show --format=%P hides parents at a shallow
  " boundary, which could incorrectly classify a merge as a fast-forward.
  let result = s:git(a:repo, ['cat-file', '-p', a:sha])
  if result.code
    throw 'gitmr: ' . join(result.lines, "\n")
  endif
  let parents = []
  for line in result.lines
    if empty(line)
      break
    endif
    if line =~# '^parent '
      call add(parents, strpart(line, 7))
    endif
  endfor
  return parents
endfunction

function! s:original(repo, mr) abort
  let refs = get(a:mr, 'diff_refs', {})
  if type(refs) != v:t_dict
    let refs = {}
  endif
  let base = s:sha(get(refs, 'base_sha', ''))
  let head = s:sha(get(refs, 'head_sha', ''))
  if empty(base) || empty(head)
    throw 'gitmr: Incomplete diff_refs: GitLab did not provide endpoints for this MR.'
  endif
  call s:require(a:repo, [base, head])
  if s:git(a:repo, ['merge-base', '--is-ancestor', base, head]).code
    throw 'gitmr: Incomplete original history or inconsistent diff_refs (shallow clone?).'
  endif
  return {'base': base, 'head': head, 'kind': 'original'}
endfunction

" Resolve immutable endpoints from MR metadata and local Git objects only.
" Never substitute today's target branch or a squash for original history.
function! gitmr#resolve(repo, mr, mode) abort
  if a:mode ==# 'commits' || get(a:mr, 'state', '') !=# 'merged'
    return s:original(a:repo, a:mr)
  endif

  let merge = s:sha(get(a:mr, 'merge_commit_sha', ''))
  let squash = s:sha(get(a:mr, 'squash_commit_sha', ''))
  if !empty(merge)
    call s:require(a:repo, [merge])
    let parents = s:parents(a:repo, merge)
    if len(parents) >= 2
      call s:require(a:repo, [parents[0]])
      return {'base': parents[0], 'head': merge, 'kind': 'merge'}
    endif
  endif

  if !empty(squash)
    call s:require(a:repo, [squash])
    let parents = s:parents(a:repo, squash)
    if len(parents) != 1
      throw 'gitmr: The squash commit does not have exactly one parent.'
    endif
    call s:require(a:repo, [parents[0]])
    return {'base': parents[0], 'head': squash, 'kind': 'squash'}
  endif

  " GitLab can leave merge_commit_sha null for a fast-forward. Its recorded
  " diff endpoints include every MR commit, unlike head^..head.
  let plan = s:original(a:repo, a:mr)
  if !empty(merge) && merge !=# plan.head
    throw 'gitmr: Merged HEAD differs from diff_refs: ambiguous final endpoints.'
  endif
  let plan.kind = 'fast-forward'
  return plan
endfunction

function! s:clean(text) abort
  return substitute(a:text, '[\x00-\x1f\x7f]', ' ', 'g')
endfunction

function! s:render(ctx) abort
  if a:ctx.cancelled || !bufexists(a:ctx.buf)
    return
  endif
  let project = get(get(a:ctx, 'project', {}), 'path_with_namespace', a:ctx.repo)
  let lines = ['GitLab MR — ' . project . ' [' . a:ctx.mode . ', page ' . a:ctx.page . ']',
        \ '<CR> final diff   c original commits   o browser   r refresh   n/p pages   q close',
        \ a:ctx.message,
        \ printf('%-7s %-9s %-19s %-18s %s', 'MR', 'Status', 'Date', 'Author', 'Title')]
  let selected = 5
  for mr in a:ctx.rows
    let date = get(mr, a:ctx.mode ==# 'merged' ? 'merged_at' : 'updated_at', '')
    let date = type(date) == v:t_string ? substitute(strpart(date, 0, 19), 'T', ' ', '') : ''
    let author = get(get(mr, 'author', {}), 'username', '')
    call add(lines, printf('%-7s %-9s %-19s %-18s %s', '!' . mr.iid,
          \ mr.state, date, s:clean(author), s:clean(mr.title)))
    if mr.iid == get(a:ctx, 'selection', 0)
      let selected = len(lines)
    endif
  endfor
  if empty(a:ctx.rows)
    call add(lines, a:ctx.busy ? 'Loading…' : 'No MRs.')
  endif
  if !empty(a:ctx.errors)
    call extend(lines, [''] + a:ctx.errors)
  endif
  call setbufvar(a:ctx.buf, '&modifiable', 1)
  call setbufline(a:ctx.buf, 1, lines)
  let old_size = len(getbufline(a:ctx.buf, 1, '$'))
  if old_size > len(lines)
    call deletebufline(a:ctx.buf, len(lines) + 1, '$')
  endif
  call setbufvar(a:ctx.buf, '&modified', 0)
  call setbufvar(a:ctx.buf, '&modifiable', 0)
  if !a:ctx.busy
    call win_execute(a:ctx.win, 'call cursor(' . selected . ', 1)')
  endif
endfunction

function! s:fail(ctx, message) abort
  let a:ctx.busy = 0
  let a:ctx.message = 'Error — details below the list (r to retry).'
  let a:ctx.errors = split(a:message, "\n")
  call s:render(a:ctx)
  echohl ErrorMsg
  echomsg '[MR] ' . get(a:ctx.errors, 0, 'Command failed.')
  echohl None
endfunction

function! s:done(ctx, Done, out, err, job, code) abort
  let output = filereadable(a:out) ? join(readfile(a:out), "\n") : ''
  let errors = filereadable(a:err) ? join(readfile(a:err), "\n") : ''
  call delete(a:out)
  call delete(a:err)
  if a:ctx.cancelled
    return
  endif
  unlet! a:ctx.job
  call a:Done(a:ctx, a:code, output, errors)
endfunction

function! s:run(ctx, argv, Done) abort
  let out = tempname()
  let err = tempname()
  " Files avoid a race between exit_cb and buffered stdout/stderr callbacks.
  let a:ctx.job = job_start(a:argv, {
        \ 'cwd': a:ctx.repo, 'in_io': 'null',
        \ 'out_io': 'file', 'out_name': out,
        \ 'err_io': 'file', 'err_name': err,
        \ 'env': {'GLAB_PAGER': 'cat', 'PAGER': 'cat', 'NO_COLOR': '1',
        \         'GIT_TERMINAL_PROMPT': '0'},
        \ 'exit_cb': function('s:done', [a:ctx, a:Done, out, err]),
        \ })
  if job_status(a:ctx.job) ==# 'fail'
    call delete(out)
    call delete(err)
    call s:fail(a:ctx, 'Unable to start ' . a:argv[0])
  endif
endfunction

function! s:decode(ctx, code, out, err) abort
  if a:code
    throw 'gitmr: ' . (empty(a:err) ? a:out : a:err . "\n" . a:out)
  endif
  try
    return json_decode(a:out)
  catch
    throw 'gitmr: Invalid glab JSON response: ' . a:out . "\n" . a:err
  endtry
endfunction

function! s:canonical(url) abort
  if a:url =~# '^\a\+://'
    let url = substitute(a:url, '^\a\+://\%([^/@]*@\)\?', '', '')
  else
    let url = substitute(a:url, '^[^/@:]*@', '', '')
    let url = substitute(url, ':', '/', '')
  endif
  return substitute(url, '\%(\.git\)\?/*$', '', '')
endfunction

function! s:remote(ctx) abort
  let project = a:ctx.project
  let urls = map([get(project, 'ssh_url_to_repo', ''), get(project, 'http_url_to_repo', '')],
        \ 's:canonical(v:val)')
  let names = s:git(a:ctx.repo, ['remote']).lines
  " Prefer an existing remote to preserve its transport and Git configuration.
  for name in names
    let result = s:git(a:ctx.repo, ['remote', 'get-url', name])
    if !result.code && index(urls, s:canonical(get(result.lines, 0, ''))) >= 0
      return name
    endif
  endfor
  let origin = s:git(a:ctx.repo, ['remote', 'get-url', 'origin'])
  let protocol = get(origin.lines, 0, '') =~# '^https\?://' ? 'http' : 'ssh'
  let url = get(project, protocol . '_url_to_repo', '')
  if empty(url)
    throw 'gitmr: No Git remote or URL is available for this project.'
  endif
  return url
endfunction

function! s:project_ready(ctx, code, out, err) abort
  try
    let a:ctx.project = s:decode(a:ctx, a:code, a:out, a:err)
    let a:ctx.remote = s:remote(a:ctx)
    call s:list(a:ctx)
  catch
    call s:fail(a:ctx, v:exception)
  endtry
endfunction

function! s:list(ctx) abort
  let order = a:ctx.mode ==# 'merged' && !a:ctx.old_server ? 'merged_at' : 'updated_at'
  let page = a:ctx.old_server ? a:ctx.scan_page : a:ctx.page
  let endpoint = 'projects/' . a:ctx.project.id . '/merge_requests?scope=all&state='
        \ . (a:ctx.mode ==# 'merged' ? 'merged' : 'opened')
        \ . '&order_by=' . order . '&sort=desc&per_page=100&page=' . page
  if a:ctx.mode ==# 'mine'
    " glab 1.53.0 supports :username and resolves the authenticated user.
    let endpoint .= '&reviewer_username=:username'
  endif
  call s:run(a:ctx, ['glab', 'api', endpoint], function('s:list_ready'))
endfunction

function! s:merge_order(left, right) abort
  let left = get(a:left, 'merged_at', '')
  let right = get(a:right, 'merged_at', '')
  return left ==# right ? 0 : left ># right ? -1 : 1
endfunction

function! s:list_ready(ctx, code, out, err) abort
  " GitLab <17.2 cannot order_by=merged_at. Scan pages and sort globally;
  " sorting only a page ordered by updated_at would miss recent merges.
  if a:code && a:ctx.mode ==# 'merged' && !a:ctx.old_server
        \ && (a:out . a:err) =~? 'order_by'
        \ && (a:out . a:err) =~? '400'
    let a:ctx.old_server = 1
    let a:ctx.scan_page = 1
    let a:ctx.scanned = []
    call s:list(a:ctx)
    return
  endif
  try
    let rows = s:decode(a:ctx, a:code, a:out, a:err)
    if type(rows) != v:t_list
      throw 'gitmr: The GitLab response does not contain a list of MRs.'
    endif
    if a:ctx.old_server
      call extend(a:ctx.scanned, rows)
      if len(rows) == 100
        let a:ctx.scan_page += 1
        let a:ctx.message = 'Sorting by merge date: ' . len(a:ctx.scanned) . ' MRs loaded…'
        call s:render(a:ctx)
        call s:list(a:ctx)
        return
      endif
      call sort(a:ctx.scanned, function('s:merge_order'))
      let rows = a:ctx.scanned[(a:ctx.page - 1) * 100 : a:ctx.page * 100 - 1]
    endif
    let a:ctx.rows = rows
    let a:ctx.busy = 0
    let a:ctx.message = len(rows) . ' MRs — 100 per page; n/p to navigate.'
    let a:ctx.errors = []
    call s:render(a:ctx)
  catch
    call s:fail(a:ctx, v:exception)
  endtry
endfunction

function! gitmr#complete(lead, line, pos) abort
  return filter(['merged', 'mine'], 'stridx(v:val, a:lead) == 0')
endfunction

function! gitmr#open(mode) abort
  let mode = empty(a:mode) ? 'opened' : a:mode
  if index(['opened', 'merged', 'mine'], mode) < 0
    echoerr 'Usage: MR [merged|mine]'
    return
  endif
  if !executable('glab') || !has('job') || !exists('*json_decode')
    echoerr 'MR requires glab and Vim with +job and json_decode().'
    return
  endif
  if !exists('*GitReview') || !exists(':Git')
    echoerr 'MR requires GitReview and vim-fugitive.'
    return
  endif
  let dir = exists('*FugitiveWorkTree') ? FugitiveWorkTree() : ''
  let result = s:git(empty(dir) ? getcwd() : dir, ['rev-parse', '--show-toplevel'])
  if result.code
    echoerr 'MR: Git repository not found. ' . join(result.lines, ' ')
    return
  endif
  let repo = result.lines[0]
  botright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal nowrap nonumber norelativenumber nolist nospell cursorline
  setlocal foldmethod=manual signcolumn=no filetype=gitmr
  execute 'file ' . fnameescape('gitmr://' . mode . '/' . bufnr(''))
  let b:gitmr = {'repo': repo, 'mode': mode, 'buf': bufnr(''), 'win': win_getid(),
        \ 'page': 1, 'rows': [], 'errors': [], 'busy': 1, 'cancelled': 0,
        \ 'old_server': 0, 'scan_page': 1, 'scanned': [], 'message': 'Loading project…'}
  nnoremap <silent><buffer> <CR> :call gitmr#select('diff')<CR>
  nnoremap <silent><buffer> c :call gitmr#select('commits')<CR>
  nnoremap <silent><buffer> o :call gitmr#browser()<CR>
  nnoremap <silent><buffer> r :call gitmr#refresh(0)<CR>
  nnoremap <silent><buffer> n :call gitmr#refresh(1)<CR>
  nnoremap <silent><buffer> p :call gitmr#refresh(-1)<CR>
  nnoremap <silent><buffer> q :close<CR>
  augroup gitmr_selector
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call gitmr#cancel(str2nr(expand('<abuf>')))
  augroup END
  call s:render(b:gitmr)
  call s:run(b:gitmr, ['glab', 'api', 'projects/:fullpath'], function('s:project_ready'))
endfunction

function! gitmr#cancel(buf) abort
  let ctx = getbufvar(a:buf, 'gitmr', {})
  if empty(ctx)
    return
  endif
  let ctx.cancelled = 1
  if has_key(ctx, 'job') && job_status(ctx.job) ==# 'run'
    call job_stop(ctx.job)
  endif
endfunction

function! s:selected() abort
  let index = line('.') - 5
  return index >= 0 && index < len(b:gitmr.rows) ? b:gitmr.rows[index] : {}
endfunction

function! gitmr#refresh(step) abort
  let ctx = b:gitmr
  if ctx.busy || (a:step < 0 && ctx.page == 1)
        \ || (a:step > 0 && len(ctx.rows) < 100)
    return
  endif
  let ctx.selection = a:step == 0 ? get(s:selected(), 'iid', 0) : 0
  let ctx.page += a:step
  let ctx.busy = 1
  let ctx.errors = []
  let ctx.message = 'Loading MRs…'
  call s:render(ctx)
  if !has_key(ctx, 'project') || !has_key(ctx, 'remote')
    call s:run(ctx, ['glab', 'api', 'projects/:fullpath'], function('s:project_ready'))
  elseif ctx.old_server && a:step != 0
    let ctx.rows = ctx.scanned[(ctx.page - 1) * 100 : ctx.page * 100 - 1]
    let ctx.busy = 0
    let ctx.message = len(ctx.rows) . ' MRs — 100 per page; n/p to navigate.'
    call s:render(ctx)
  else
    let ctx.scan_page = 1
    let ctx.scanned = []
    call s:list(ctx)
  endif
endfunction

function! gitmr#browser() abort
  let mr = s:selected()
  if !empty(mr)
    " Vim's bundled netrw browser helper respects the configured browser.
    call netrw#BrowseX(mr.web_url, 0)
  endif
endfunction

function! gitmr#select(mode) abort
  let ctx = b:gitmr
  let mr = s:selected()
  if ctx.busy || empty(mr)
    return
  endif
  let ctx.selection = mr.iid
  let ctx.review_mode = a:mode
  let ctx.busy = 1
  let ctx.errors = []
  let ctx.attempted = {}
  let ctx.fetch_errors = []
  let ctx.message = 'Loading !' . mr.iid . '…'
  call s:render(ctx)
  let endpoint = 'projects/' . ctx.project.id . '/merge_requests/' . mr.iid
  call s:run(ctx, ['glab', 'api', endpoint], function('s:mr_ready'))
endfunction

function! s:mr_ready(ctx, code, out, err) abort
  try
    let a:ctx.mr = s:decode(a:ctx, a:code, a:out, a:err)
    call s:ensure(a:ctx)
  catch
    call s:fail(a:ctx, v:exception)
  endtry
endfunction

function! s:ensure(ctx) abort
  try
    let plan = gitmr#resolve(a:ctx.repo, a:ctx.mr, a:ctx.review_mode)
  catch /^gitmr:missing:/
    let missing = split(strpart(v:exception, len('gitmr:missing:')), ',')
    let candidates = missing + ['refs/merge-requests/' . a:ctx.mr.iid . '/head',
          \ 'refs/heads/' . a:ctx.mr.target_branch]
    for ref in candidates
      if !has_key(a:ctx.attempted, ref)
        let a:ctx.attempted[ref] = 1
        let dest = 'refs/vim-mr/' . a:ctx.project.id . '/' . a:ctx.mr.iid . '/'
              \ . (ref =~# '^refs/' ? (ref =~# '^refs/heads/' ? 'target' : 'head') : ref)
        let a:ctx.message = 'Fetching !' . a:ctx.mr.iid . ': ' . ref . '…'
        call s:render(a:ctx)
        call s:run(a:ctx, ['git', 'fetch', '--refmap=', '--no-tags', '--no-write-fetch-head',
              \ '--recurse-submodules=no', '--', a:ctx.remote, '+' . ref . ':' . dest],
              \ function('s:fetched'))
        return
      endif
    endfor
    let message = a:ctx.review_mode ==# 'commits'
          \ ? 'Original history is unavailable. Use <CR> for the final diff; no history is reconstructed.'
          \ : 'Historical refs are unavailable: ' . join(missing, ', ')
    call s:fail(a:ctx, message . "\n" . join(a:ctx.fetch_errors, "\n"))
    return
  catch
    call s:fail(a:ctx, v:exception)
    return
  endtry
  call s:launch(a:ctx, plan)
endfunction

function! s:fetched(ctx, code, out, err) abort
  if a:code
    let error = a:err . "\n" . a:out
    call add(a:ctx.fetch_errors, error)
    " Missing/deleted refs are expected for old MRs. Preserve all diagnostics
    " if no endpoint is recoverable; stop immediately on auth/network errors.
    if error !~? 'couldn''t find remote ref\|not our ref\|unadvertised object\|does not allow request'
      call s:fail(a:ctx, error)
      return
    endif
  endif
  call s:ensure(a:ctx)
endfunction

function! s:launch(ctx, plan) abort
  " A review gets its own tab: GitQfDiff's existing :only stays in that tab,
  " and no edited file or window needs to be abandoned to open the selector.
  tabnew
  execute 'lcd ' . fnameescape(a:ctx.repo)
  try
    execute 'Gedit ' . a:plan.head . ':'
    if a:ctx.review_mode ==# 'commits'
      execute 'Gclog! --reverse ' . a:plan.base . '..' . a:plan.head
      copen
      echomsg '[MR] !' . a:ctx.mr.iid . ': original commits; gc to open a commit.'
    else
      call GitReview(a:plan.base, a:plan.head)
      copen
      echomsg '[MR] !' . a:ctx.mr.iid . ': ' . a:plan.kind . '; gd to open a diff.'
    endif
    call win_execute(a:ctx.win, 'close')
  catch
    tabclose
    call s:fail(a:ctx, v:exception)
  endtry
endfunction
