set nocompatible encoding=utf-8 nomore
let s:root = $GITMR_TEST_ROOT
let s:config = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:config)
let s:f = json_decode(join(readfile(s:root . '/fixtures.json'), "\n"))

function! s:git(repo, args) abort
  return systemlist(join(map(['git', '-C', a:repo] + a:args, 'shellescape(v:val)'), ' '))
endfunction

function! s:expect(mr, repo, mode, base, head, kind) abort
  let plan = gitmr#resolve(a:repo, a:mr, a:mode)
  call assert_equal([a:base, a:head, a:kind], [plan.base, plan.head, plan.kind])
  return plan
endfunction

function! s:expect_error(mr, repo, mode, pattern) abort
  try
    call gitmr#resolve(a:repo, a:mr, a:mode)
    call assert_report('Expected failure: ' . a:pattern)
  catch
    call assert_match(a:pattern, v:exception)
  endtry
endfunction

" Real Git graphs: target changes before and after merge must be excluded.
let s:plan = s:expect(s:f.mrs.merge, s:f.repo, 'diff', s:f.target, s:f.merge, 'merge')
call assert_equal(['service.rb', 'spec.rb'],
      \ s:git(s:f.repo, ['diff', '--name-only', s:plan.base, s:plan.head]))
call assert_equal(['resolved MR'], s:git(s:f.repo, ['show', s:plan.head . ':service.rb']))
call s:expect(s:f.mrs.merge, s:f.repo, 'commits', s:f.base, s:f.original, 'original')
call s:expect(s:f.mrs.opened, s:f.repo, 'diff', s:f.base, s:f.original, 'original')
call s:expect(s:f.mrs.squash, s:f.squash_repo, 'diff', s:f.squash_base, s:f.squash, 'squash')
call s:expect(s:f.mrs.squash_merge, s:f.repo, 'diff', s:f.squash_base, s:f.squash_merge, 'merge')
let s:plan = s:expect(s:f.mrs.ff, s:f.repo, 'diff', s:f.base, s:f.mrs.ff.diff_refs.head_sha, 'fast-forward')
call assert_equal(['ff_one.rb', 'ff_two.rb'],
      \ s:git(s:f.repo, ['diff', '--name-only', s:plan.base, s:plan.head]))
call s:expect_error(s:f.mrs.squash, s:f.squash_repo, 'commits', '^gitmr:missing:')
call s:expect_error(s:f.mrs.merge, s:f.shallow_repo, 'diff', '^gitmr:missing:' . s:f.target)
let s:bad = deepcopy(s:f.mrs.ff)
let s:bad.merge_commit_sha = s:f.ff_later
call s:expect_error(s:bad, s:f.repo, 'diff', 'ambiguous final endpoints')
let s:bad.diff_refs = v:null
call s:expect_error(s:bad, s:f.repo, 'commits', 'Incomplete diff_refs')

" Stub only the Fugitive UI boundary, leaving the async API/fetch code real.
let g:reviews = []
function! GitReview(base, head) abort
  call add(g:reviews, [a:base, a:head])
  call setqflist([{'text': 'MR diff', 'valid': 1}], ' ')
endfunction
command! -nargs=* Git echo ''
command! -nargs=1 Gedit let g:review_tree = <q-args>
command! -bang -nargs=+ Gclog let g:review_log = <q-args>

function! s:wait(ctx) abort
  let deadline = reltime()
  while a:ctx.busy && !a:ctx.cancelled && reltimefloat(reltime(deadline)) < 5
    sleep 10m
  endwhile
  call assert_true(!a:ctx.busy || a:ctx.cancelled, 'Async operation timed out')
endfunction

function! s:open(mode, repo) abort
  execute 'cd ' . fnameescape(a:repo)
  call gitmr#open(a:mode)
  let ctx = b:gitmr
  call s:wait(ctx)
  call assert_equal([], ctx.errors)
  return ctx
endfunction

let s:before_qf = [{'text': 'existing quickfix', 'valid': 1}]
call setqflist(s:before_qf, ' ')
let s:qf_id = getqflist({'id': 0}).id
let s:ctx = s:open('merged', s:f.fetch_repo)
call assert_equal('nofile', &buftype)
call assert_equal('wipe', &bufhidden)
call assert_equal(1, maparg('<CR>', 'n', 0, 1).buffer)
call assert_equal(1, maparg('r', 'n', 0, 1).buffer)
call assert_equal(s:qf_id, getqflist({'id': 0}).id)
call assert_equal([4, 3, 2, 1], map(copy(s:ctx.rows), 'v:val.iid'))
call assert_equal(2, len(readfile(s:root . '/api.log')), 'No per-row API calls')
call gitmr#refresh(0)
call s:wait(s:ctx)
call assert_equal(3, len(readfile(s:root . '/api.log')), 'Refresh uses one list request')

" Selecting an old merge fetches its SHA without touching dirty local state.
let s:head = s:git(s:f.fetch_repo, ['rev-parse', 'HEAD'])
let s:index = s:git(s:f.fetch_repo, ['diff', '--cached', '--binary'])
let s:worktree = s:git(s:f.fetch_repo, ['diff', '--binary'])
let s:status = s:git(s:f.fetch_repo, ['status', '--porcelain'])
let s:refs = s:git(s:f.fetch_repo, ['for-each-ref', '--format=%(refname) %(objectname)',
      \ 'refs/heads/', 'refs/remotes/', 'refs/tags/'])
call cursor(8, 1)
call gitmr#select('diff')
call s:wait(s:ctx)
call assert_equal([[s:f.target, s:f.merge]], g:reviews)
call assert_equal(s:f.merge . ':', g:review_tree)
call assert_false(bufexists(s:ctx.buf))
call assert_equal(2, tabpagenr('$'))
call assert_equal(s:head, s:git(s:f.fetch_repo, ['rev-parse', 'HEAD']))
call assert_equal(s:index, s:git(s:f.fetch_repo, ['diff', '--cached', '--binary']))
call assert_equal(s:worktree, s:git(s:f.fetch_repo, ['diff', '--binary']))
call assert_equal(s:status, s:git(s:f.fetch_repo, ['status', '--porcelain']))
call assert_equal(s:refs, s:git(s:f.fetch_repo, ['for-each-ref', '--format=%(refname) %(objectname)',
      \ 'refs/heads/', 'refs/remotes/', 'refs/tags/']))
tabclose

let s:ctx = s:open('mine', s:f.repo)
call assert_equal([5], map(copy(s:ctx.rows), 'v:val.iid'))
call cursor(5, 1)
call gitmr#select('commits')
call s:wait(s:ctx)
call assert_equal('--reverse ' . s:f.base . '..' . s:f.original, g:review_log)
tabclose

" Expired original squash objects: preserve the current quickfix, explain
" that history is unavailable, and still allow the exact final squash diff.
let s:ctx = s:open('merged', s:f.squash_repo)
let s:qf_id = getqflist({'id': 0}).id
call cursor(7, 1)
call gitmr#select('commits')
call s:wait(s:ctx)
call assert_match('Original history is unavailable', join(s:ctx.errors, "\n"))
call assert_equal(s:qf_id, getqflist({'id': 0}).id)
call assert_true(bufexists(s:ctx.buf))
call gitmr#select('diff')
call s:wait(s:ctx)
call assert_equal([s:f.squash_base, s:f.squash], g:reviews[-1])
tabclose

call writefile([], s:root . '/old_server')
let s:ctx = s:open('merged', s:f.repo)
call assert_equal(101, s:ctx.rows[0].iid, 'Sort all API pages before slicing')
call assert_equal(100, len(s:ctx.rows))
call gitmr#refresh(1)
call assert_equal(1, len(s:ctx.rows))
call gitmr#refresh(-1)
call assert_equal(101, s:ctx.rows[0].iid)
close
call delete(s:root . '/old_server')

call writefile([], s:root . '/auth_error')
call gitmr#open('')
let s:ctx = b:gitmr
call s:wait(s:ctx)
call assert_match('401 Unauthorized', join(s:ctx.errors, "\n"))
call delete(s:root . '/auth_error')
call gitmr#refresh(0)
call s:wait(s:ctx)
call assert_equal([], s:ctx.errors)
close

call writefile([], s:root . '/slow')
let s:qf_id = getqflist({'id': 0}).id
call gitmr#open('')
let s:ctx = b:gitmr
close
call assert_true(s:ctx.cancelled)
call assert_equal(s:qf_id, getqflist({'id': 0}).id)
call delete(s:root . '/slow')
sleep 50m

if !empty(v:errors)
  for error in v:errors
    echomsg error
  endfor
  cquit
endif
qa!
