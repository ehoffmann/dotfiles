set nomore
let s:runtime = $VIM_CONFIG_TEST_RUNTIME

" Exercise the normal startup entry point, including project overrides.
call assert_equal('', v:errmsg)
call assert_equal('gruvbox', g:colors_name)
call assert_equal('light', &background)
call assert_equal(1024, &synmaxcol)
call assert_equal(7, &scrolloff)
call assert_equal(1, g:config_test_project_loads)
call assert_equal(31, len(g:config_test_plugins))
for s:command in ['Files', 'Rg', 'Review', 'ReviewLast', 'ReviewEnd',
      \ 'GitReview', 'MR', 'Tabs', 'Glow', 'Today', 'OpenSpec',
      \ 'ReviewContext', 'ReviewContextList', 'ReviewContextMarks', 'ReviewSummary',
      \ 'ReviewFiles', 'ReviewCommits']
  call assert_equal(2, exists(':' . s:command), s:command)
endfor
call assert_equal(0, exists(':ReviewBranch'), 'Renamed to :ReviewFiles')
for s:function in ['ReviewGitGutter', 'GitReview', 'GitQfDiff',
      \ 'GitQfReviewCommit', 'Glow', 'Tabs', 'Today', 'OpenRubyAPI',
      \ 'OpenCorrespondingSpec']
  call assert_true(exists('*' . s:function), s:function)
endfor
for s:function in ['gitreview#open', 'glow#open', 'navigation#tabs', 'rubytools#api',
      \ 'reviewcontext#show']
  call assert_false(exists('*' . s:function), 'Must remain lazy: ' . s:function)
endfor
" The fixture lives under /tmp, which 'wildignore' excludes; bypass it.
call assert_true(index(globpath(&runtimepath, 'snippets/_.snippets', 1, 1),
      \ s:runtime . '/snippets/_.snippets') >= 0)
let s:autocmds = execute('autocmd dotfiles_filetypes')
      \ . execute('autocmd dotfiles_ftplugin')
let s:statusline = &statusline
let g:git_review_left = 'keep-review-state'
" Vim started with -u leaves $MYVIMRC empty, so reload the link directly.
let v:errmsg = ''
source ~/.vimrc
call assert_equal('', v:errmsg)
call assert_equal(s:autocmds, execute('autocmd dotfiles_filetypes')
      \ . execute('autocmd dotfiles_ftplugin'))
call assert_equal(s:statusline, &statusline)
call assert_equal('keep-review-state', g:git_review_left)
call assert_equal(2, g:config_test_project_loads)

" Moved event handlers must remain single after reloading and revisiting.
doautocmd BufWinEnter
doautocmd BufWinEnter
call assert_equal(3, len(filter(getmatches(),
      \ 'index(w:dotfiles_keyword_matches, v:val.id) >= 0')))

" Mappings and options must clean up when changing filetype in one buffer.
enew!
setlocal filetype=rust
call assert_equal(1, maparg('<C-s>', 'i', 0, 1).buffer)
call assert_equal(2, &softtabstop)
setlocal filetype=text
call assert_equal('', maparg('<C-s>', 'i'))
call assert_false(exists('b:dotfiles_rust_settings'))

enew!
setlocal filetype=go
call assert_equal(0, &l:list)
call assert_equal(1, &g:list)
setlocal filetype=text
call assert_equal(1, &l:list)

enew!
let b:gutentags_files = {'ctags': '/tmp/dotfiles-tags-cache'}
setlocal filetype=ruby
call assert_equal(1, len(filter(split(&l:tags, ','),
      \ 'v:val ==# b:gutentags_files.ctags')), 'Legacy symlinks must not duplicate settings')
call assert_match('rubytag#jump', maparg('<C-]>', 'n'))
for s:key in ['hc', 'hh', 'hr', 'fr']
  call assert_equal(1, maparg(' ' . s:key, 'n', 0, 1).buffer)
endfor
call assert_match('lib/', &l:path)
setlocal filetype=text
call assert_equal('', maparg(' hc', 'n'))
call assert_equal('', maparg('<C-]>', 'n'))
call assert_false(exists('b:dotfiles_ruby_settings'))
setlocal filetype=ruby
call assert_equal(1, maparg(' hc', 'n', 0, 1).buffer)

enew!
let s:errorformat = &g:errorformat
setlocal filetype=c
call assert_equal('make -k NAME=%:r', &l:makeprg)
call assert_equal('%f:%l:%c: %m', &l:errorformat)
call assert_equal(s:errorformat, &g:errorformat)
setlocal filetype=text
call assert_equal(s:errorformat, &errorformat)

for s:ft in ['javascript', 'html']
  enew!
  execute 'setlocal filetype=' . s:ft
  call assert_equal([2, 2, 2, 1], [&tabstop, &shiftwidth, &softtabstop, &expandtab])
endfor

enew!
setlocal filetype=yaml
call assert_equal('indent', &foldmethod)
call assert_equal(99, &foldlevel)
call assert_equal(-1, stridx(&indentkeys, '<:>'))
call assert_true(exists('b:dotfiles_yaml_indent'))
setlocal filetype=text
call assert_false(exists('b:dotfiles_yaml_indent'))

enew!
setlocal filetype=fern
call assert_match('TmuxNavigateLeft', maparg('<C-h>', 'n'))
call assert_equal(1, maparg('<C-h>', 'n', 0, 1).buffer)
setlocal filetype=text
call assert_equal('', maparg('<C-h>', 'n'))

" A saved view restores the cursor but not an outdated fold method.
call writefile(['a:', '  b: 1', 'c:', '  d: 2'], 'view.yml')
edit view.yml
call cursor(3, 1)
setlocal foldmethod=manual
mkview 1
bwipe!
edit view.yml
call assert_equal('indent', &l:foldmethod)
call assert_equal(3, line('.'))
bwipe!

" Custom detection still runs from outside the checkout.
for [s:name, s:ft] in [['Guardfile', 'ruby'], ['.env.local', 'sh'],
      \ ['app.env.test', 'sh'], ['example.go', 'go'], ['example.yml', 'yaml']]
  execute 'edit ' . s:name
  call assert_equal(s:ft, &filetype, s:name)
endfor

" Public review adapters still dispatch to Fugitive with the same arguments.
command! -nargs=* Git let g:config_test_git_args = <q-args>
GitReview base-sha head-sha
call assert_equal(['base-sha', 'head-sha'], [g:git_review_left, g:git_review_right])
call assert_equal('difftool --name-only base-sha head-sha', g:config_test_git_args)
call GitReview('origin/main')
call assert_equal('', g:git_review_right)
call assert_equal('difftool --name-only origin/main', g:config_test_git_args)
call setqflist([{'filename': 'example.rb', 'lnum': 1, 'module': 'commit-sha'}])
copen
call assert_equal(1, maparg('gd', 'n', 0, 1).buffer)
call assert_equal(1, maparg('gc', 'n', 0, 1).buffer)
call GitQfReviewCommit()
call assert_equal('difftool --name-only commit-sha^ commit-sha', g:config_test_git_args)
cclose
Tabs
call assert_equal(tabpagenr('$'), len(g:config_test_tabs))

enew!
setlocal filetype=gitcommit
call assert_match('GitWordAdd', execute('syntax list GitWordAdd'))
setlocal syntax=OFF
setlocal syntax=gitcommit
call assert_match('GitWordAdd', execute('syntax list GitWordAdd'))

" Glow must leave room for line numbers, even with a wider number column.
if has('terminal')
  enew!
  call setline(1, '# Preview')
  setlocal nonumber relativenumber nowrap nolinebreak
  let s:source_buf = bufnr('%')
  for s:numberwidth in [4, 8]
    let &l:numberwidth = s:numberwidth
    Glow
    let s:preview_buf = bufnr('%')
    for s:attempt in range(100)
      call term_wait(s:preview_buf, 20)
      if term_getstatus(s:preview_buf) =~# 'finished'
        break
      endif
    endfor
    call assert_match('finished', term_getstatus(s:preview_buf))
    " Let Vim read the last output of the finished job.
    call term_wait(s:preview_buf, 50)
    call assert_equal([1, 0, 1, 1], [&l:number, &l:relativenumber, &l:wrap, &l:linebreak])
    let s:args = json_decode(join(readfile($VIM_CONFIG_TEST_GLOW_ARGS), "\n"))
    let s:width = winwidth(0) - s:numberwidth
    call assert_equal(['-s', 'light', '-w', string(s:width)], s:args[:3])
    call assert_equal(repeat('x', s:width), getline(1))
    call assert_false(filereadable(s:args[-1]), 'Temporary Markdown must be removed')
    tabclose!
    call assert_equal(s:source_buf, bufnr('%'))
    call assert_equal([0, 1, 0, 0], [&l:number, &l:relativenumber, &l:wrap, &l:linebreak])
  endfor
endif

" Agent prompts go through a named tmux buffer with bracketed paste, and
" Enter is only sent once the paste succeeded.
function! s:tmux_calls() abort
  let l:log = $VIM_CONFIG_TEST_TMUX_LOG
  let l:calls = filereadable(l:log) ? map(readfile(l:log), 'json_decode(v:val)') : []
  call delete(l:log)
  return l:calls
endfunction

call assert_equal(2, exists(':AgentExplain'))
call assert_equal(2, exists(':AgentSelectPane'))
call assert_false(exists('*AgentExplain'), 'Agent helpers must be script-local')
let $TMUX = '/tmp/tmux-test/default,1,0'
let $TMUX_PANE = '%1'
enew!
call setline(1, ['first', 'second', 'third'])
file agent_sample.txt
let g:agent_pane = '%9'
2,3AgentExplain
call assert_equal([
      \ {'args': ['load-buffer', '-b', 'vim-agent', '-'],
      \  'stdin': "Explain this code from agent_sample.txt (lines 2-3):\n\nsecond\nthird"},
      \ {'args': ['paste-buffer', '-p', '-d', '-b', 'vim-agent', '-t', '%9']},
      \ {'args': ['send-keys', '-t', '%9', 'Enter']}], s:tmux_calls())

let $VIM_CONFIG_TEST_TMUX_FAIL = 'paste-buffer'
AgentExplain
call assert_equal(['load-buffer', 'paste-buffer', 'delete-buffer'],
      \ map(s:tmux_calls(), 'v:val.args[0]'), 'Enter must not follow a failed paste')
call assert_match("tmux paste-buffer failed: can't find pane", execute('messages'))
let $VIM_CONFIG_TEST_TMUX_FAIL = ''

" Vim's own pane is never offered, so there is nothing to select here.
unlet g:agent_pane
messages clear
AgentExplain
call assert_match('No other tmux pane in this window', execute('messages'))
call assert_equal([['list-panes']], map(s:tmux_calls(), 'v:val.args[:0]'))
call assert_false(exists('g:agent_pane'))
let $TMUX = ''
AgentExplain
call assert_equal([], s:tmux_calls(), 'tmux must not be used outside tmux')
bwipeout!

" Files outside repositories with a review context must not load it.
call assert_false(exists('*reviewcontext#marks'), 'Review context must remain lazy')

" Review context picks the narrowest annotation covering the cursor line,
" through symlinks, skips malformed entries, and flags stale line ranges.
call assert_equal(':ReviewContext<CR>', maparg(' k', 'n'))
call assert_equal(':ReviewSummary<CR>', maparg(' K', 'n'))
let s:repo = $VIM_CONFIG_TEST_ROOT . '/review repo'
let s:git = 'git -C ' . shellescape(s:repo)
call mkdir(s:repo . '/app', 'p')
call mkdir(s:repo . '/.review', 'p')
let s:review_file = s:repo . '/app/model.rb'
let s:review_json = s:repo . '/.review/context.json'
call writefile(map(range(1, 12), '"line " . v:val'), s:review_file)
call system(s:git . ' init -q && ' . s:git . ' add app && ' . s:git
      \ . ' -c user.name=Test -c user.email=test@example.com commit -qm Initial')
call assert_equal(0, v:shell_error)
let s:review_head = trim(system(s:git . ' rev-parse HEAD'))
let s:review_data = {'base': s:review_head, 'head': s:review_head, 'annotations': [
      \ 'not an object',
      \ {'path': 'app/model.rb', 'start': '3', 'end': 5, 'symbol': 'Bad range'},
      \ {'path': 'app/other.rb', 'start': 1, 'end': 12, 'symbol': 'Other file'},
      \ {'path': 'app/model.rb', 'start': 1, 'end': 10, 'symbol': 'Model'},
      \ {'path': 'app/model.rb', 'start': 3, 'end': 5, 'symbol': 'Model#save',
      \  'kind': 'method',
      \  'summary': "Saves the model.\nReturns false on failure.",
      \  'change': 'Validates first.', 'risks': ['Slower saves', 3, 'Callbacks']},
      \ ]}
call writefile([json_encode(s:review_data)], s:review_json)
call assert_equal({'lines': ['Model#save (method)', repeat('─', 45), '',
      \ 'DESCRIPTION', 'Saves the model.', 'Returns false on failure.', '',
      \ 'CHANGE', 'Validates first.', '',
      \ 'RISKS', '- Slower saves', '- Callbacks', '',
      \ 'q / Esc: close']}, reviewcontext#annotation(s:review_file, 4))
call assert_equal({'lines': ['Model', repeat('─', 45), '', 'q / Esc: close']},
      \ reviewcontext#annotation(s:review_file, 9))
call assert_equal({'message': 'no annotation at cursor', 'error': 0},
      \ reviewcontext#annotation(s:review_file, 11))
let s:review_link = $VIM_CONFIG_TEST_ROOT . '/model-link.rb'
call system('ln -s ' . shellescape(s:review_file) . ' ' . shellescape(s:review_link))
call assert_equal(reviewcontext#annotation(s:review_file, 4),
      \ reviewcontext#annotation(s:review_link, 4), 'Symlinks must resolve')

" Each reason for stale ranges is reported, after the title.
call assert_equal(['! Unsaved changes in this buffer', 'Line ranges may be stale.', ''],
      \ reviewcontext#annotation(s:review_file, 9, 1).lines[3:5])
let s:review_data.head = s:review_head[:11]
call writefile([json_encode(s:review_data)], s:review_json)
call assert_equal(4, len(reviewcontext#annotation(s:review_file, 9).lines),
      \ 'An abbreviated head must still match')
let s:review_data.head = repeat('0', 40)
call writefile([json_encode(s:review_data)], s:review_json)
call assert_equal('! HEAD moved since this review was generated',
      \ reviewcontext#annotation(s:review_file, 9).lines[3])
let s:review_data.head = s:review_head
call writefile([json_encode(s:review_data)], s:review_json)
call system('touch -d 2000-01-01 ' . shellescape(s:review_json))
call assert_equal('! File changed after this review was generated',
      \ reviewcontext#annotation(s:review_file, 9).lines[3])
call writefile([json_encode(s:review_data)], s:review_json)

execute 'edit ' . fnameescape(s:review_file)
call cursor(4, 1)
ReviewContext
call assert_equal(1, len(popup_list()))
call assert_equal('Model#save (method)', getbufline(winbufnr(popup_list()[0]), 1)[0])
call popup_clear()
call setline(1, 'edited')
ReviewContext
call assert_equal('! Unsaved changes in this buffer',
      \ getbufline(winbufnr(popup_list()[0]), 4)[0])
call popup_clear()

" Marks show where annotations start, and follow the toggle and new contexts.
edit!
let s:review_buf = bufnr('%')
function! s:review_marks() abort
  return map(prop_list(1, {'bufnr': s:review_buf, 'end_lnum': -1,
        \ 'types': ['reviewcontext']}), '[v:val.lnum, v:val.text]')
endfunction
call assert_equal([[1, '  ◆ review'], [3, '  ◆ 2 risks']], s:review_marks())
ReviewContextMarks
call assert_equal([], s:review_marks())
ReviewContextMarks
call assert_equal([[1, '  ◆ review'], [3, '  ◆ 2 risks']], s:review_marks())
call add(s:review_data.annotations, {'path': 'app/model.rb', 'start': 6, 'end': 7,
      \ 'symbol': 'Extra', 'kind': 'block', 'risks': ['One']})
call add(s:review_data.annotations, {'path': 'app/model.rb', 'start': 1, 'end': 2,
      \ 'symbol': 'Header'})
call writefile([json_encode(s:review_data)], s:review_json)
call system('touch -d @' . (localtime() + 60) . ' ' . shellescape(s:review_json))
doautocmd BufEnter
call assert_equal([[1, '  ◆ review'], [3, '  ◆ 2 risks'], [6, '  ◆ 1 risk']],
      \ s:review_marks(), 'A regenerated context must refresh the marks')
let g:review_context_signs = 1
edit!
call assert_equal([], s:review_marks())
call assert_equal([1, 3, 6], map(sign_getplaced(s:review_buf,
      \ {'group': 'reviewcontext'})[0].signs, 'v:val.lnum'))
unlet g:review_context_signs
edit!
call assert_equal([], sign_getplaced(s:review_buf, {'group': 'reviewcontext'})[0].signs)

" The list holds every annotation, enclosing ranges first.
ReviewContextList
call assert_equal('Review context', getloclist(0, {'title': 1}).title)
call assert_equal([
      \ ['model.rb', 1, 'Model'],
      \ ['model.rb', 1, 'Header'],
      \ ['model.rb', 3, 'Model#save (method) [2 risks]: Saves the model.'],
      \ ['model.rb', 6, 'Extra (block) [1 risk]'],
      \ ['other.rb', 1, 'Other file']],
      \ map(getloclist(0), '[fnamemodify(bufname(v:val.bufnr), ":t"), v:val.lnum, v:val.text]'))
lclose

" The summary orders the contract by impact, links references to the code,
" and skips malformed entries.
let s:review_data.summary = {
      \ 'intent': "Validate before saving.\nKeeps callers unchanged.",
      \ 'goals': ['Reject invalid models'],
      \ 'non_goals': ['Change the schema', 4],
      \ 'contract': [
      \   {'text': 'Save signature is unchanged', 'status': 'unchanged'},
      \   {'text': 'Invalid models now raise', 'status': 'breaking',
      \    'ref': {'path': 'app/model.rb', 'start': 3}},
      \   {'text': 'Validation runs first', 'status': 'changed',
      \    'ref': {'path': 'app/model.rb', 'start': '3'}},
      \   'not an object'],
      \ 'reading_order': [
      \   {'path': 'app/model.rb', 'start': 6, 'why': 'Start here'},
      \   {'path': 'app/model.rb'},
      \   {'path': 'app/model.rb', 'start': 1}],
      \ 'tests': ['Confirmé : covered'],
      \ 'risks': [],
      \ 'questions': ['Backfill?']}
call writefile([json_encode(s:review_data)], s:review_json)
let s:review_tab = tabpagenr()
ReviewSummary
call assert_equal(['nofile', 'markdown', 0], [&buftype, &filetype, &modifiable])
call assert_equal(['# Review summary', '',
      \ printf('base `%s` → head `%s`', s:review_head[:6], s:review_head[:6]), '',
      \ '## Intent', 'Validate before saving.', 'Keeps callers unchanged.', '',
      \ '## Goals', '- Reject invalid models', '',
      \ '## Non-goals', '- Change the schema', '',
      \ '## Contract',
      \ '- [breaking] Invalid models now raise (app/model.rb:3)',
      \ '- [changed] Validation runs first',
      \ '- [unchanged] Save signature is unchanged', '',
      \ '## Reading order', '1. app/model.rb:6 — Start here', '2. app/model.rb:1', '',
      \ '## Tests', '- Confirmé : covered', '',
      \ '## Questions', '- Backfill?', '',
      \ '<CR> on a file reference opens it beside this summary; q closes.'],
      \ getline(1, '$'))

" <CR> opens references beside the summary and then reuses that window.
call cursor(1, 1)
execute "normal \<CR>"
call assert_equal('Review summary', bufname('%'), 'Lines without a reference stay put')
call cursor(search('^1\. '), 1)
execute "normal \<CR>"
call assert_equal([s:review_file, 6, 2], [resolve(expand('%:p')), line('.'), winnr('$')])
wincmd h
call cursor(search('^- \[breaking\]'), 1)
execute "normal \<CR>"
call assert_equal([s:review_file, 3, 2], [resolve(expand('%:p')), line('.'), winnr('$')])

" A new summary replaces the previous one, and q closes it with its tab.
ReviewSummary
call assert_equal(1, len(filter(getbufinfo(), 'has_key(v:val.variables, "review_summary_refs")')))
let s:summary_tabs = tabpagenr('$')
normal q
call assert_equal(s:summary_tabs - 1, tabpagenr('$'))
call assert_equal(0, len(filter(getbufinfo(), 'has_key(v:val.variables, "review_summary_refs")')))
execute 'tabnext' s:review_tab
tabonly

call remove(s:review_data, 'summary')
call writefile([json_encode(s:review_data)], s:review_json)
messages clear
ReviewSummary
call assert_equal(s:review_tab, tabpagenr('$'), 'A context without summary must not open a tab')
let s:review_data.summary = 'not an object'
call writefile([json_encode(s:review_data)], s:review_json)
ReviewSummary
call assert_match('expected a summary object', execute('messages'))
call assert_equal(s:review_tab, tabpagenr('$'), 'Errors must not open a tab')

" Fugitive blobs, as opened by gd after :GitReview, get annotations and marks
" when they match the working-tree file; other versions get a warning only.
function! FugitiveReal(...) abort
  return substitute(a:0 ? a:1 : @%, '^fugitive://\(.*\)/\.git//[^/]\+/', '\1/', '')
endfunction
function! s:open_blob(rev, lines) abort
  execute 'edit ' . fnameescape('fugitive://' . s:repo . '/.git//' . a:rev . '/app/model.rb')
  call setline(1, a:lines)
  setlocal nomodified
  " Fugitive fires BufReadPost once the blob is loaded.
  doautocmd <nomodeline> BufReadPost
  let s:review_buf = bufnr('%')
endfunction
call s:open_blob(s:review_head, readfile(s:review_file))
call assert_equal([[1, '  ◆ review'], [3, '  ◆ 2 risks'], [6, '  ◆ 1 risk']],
      \ s:review_marks(), 'A blob matching the work tree must be marked')
call cursor(4, 1)
ReviewContext
call assert_equal(['Model#save (method)', 'DESCRIPTION'],
      \ map([1, 4], 'getbufline(winbufnr(popup_list()[0]), v:val)[0]'))
call popup_clear()
ReviewContextList
call assert_equal(5, len(getloclist(0)))
lclose
" Without Fugitive, a reloaded blob would come back empty.
bwipeout!
call s:open_blob(repeat('1', 40), ['added'] + readfile(s:review_file))
call assert_equal([], s:review_marks(), 'Another version must not be marked')
call cursor(4, 1)
ReviewContext
call assert_equal('! This version differs from the working-tree file',
      \ getbufline(winbufnr(popup_list()[0]), 4)[0])
call popup_clear()
bwipeout!

delfunction FugitiveReal

" ReviewFiles lists work tree files against the merge base, so gd opens them.
let s:cwd = getcwd()
execute 'cd ' . fnameescape(s:repo)
call system(s:git . ' branch -q base')
call system('printf "line 13\n" >> ' . shellescape(s:review_file) . ' && ' . s:git
      \ . ' -c user.name=Test -c user.email=test@example.com commit -qam Second')
let g:config_test_git_args = ''
ReviewFiles base
call assert_equal('difftool --name-only ' . s:review_head, g:config_test_git_args)
call assert_equal([s:review_head, ''], [g:git_review_left, g:git_review_right])
let g:config_test_git_args = ''
messages clear
ReviewFiles
call assert_equal('', g:config_test_git_args, 'A missing origin/main must not start a review')
call assert_match('ReviewFiles: could not find the merge base with origin/main',
      \ execute('messages'))

" Read marks: x records the reviewed version of a file, gr shows the files
" left to read, and a mark turns to ~ when the file changes.
function! ConfigTestDifftool(args) abort
  let g:config_test_git_args = a:args
  if get(g:, 'config_test_difftool_fail', 0)
    return
  endif
  call setqflist([], ' ', {'title': ':Git ' . a:args,
        \ 'items': map(copy(g:config_test_difftool_files), '{"filename": v:val, "text": ""}')})
endfunction
command! -nargs=* Git call ConfigTestDifftool(<q-args>)
call writefile(['extra'], s:repo . '/app/extra.rb')
call system(s:git . ' add app && ' . s:git
      \ . ' -c user.name=Test -c user.email=test@example.com commit -qm Third')
let s:read_head = trim(system(s:git . ' rev-parse HEAD'))
let s:blob = 'fugitive://' . s:repo . '/.git//' . s:read_head . '/app/'
let g:config_test_difftool_files = [s:blob . 'model.rb', s:blob . 'extra.rb']
function! s:review_list() abort
  let l:list = getqflist({'title': 1, 'items': 1})
  return [l:list.title, map(l:list.items, 'v:val.text')]
endfunction
GitReview base HEAD
call assert_equal([':Git difftool --name-only base HEAD — 0/2 read', ['', '']],
      \ s:review_list())
copen
normal x
call assert_equal([':Git difftool --name-only base HEAD — 1/2 read', ['✓', '']],
      \ s:review_list())
if has('patch-8.2.0959')
  call assert_equal(['✓ app/model.rb', '  app/extra.rb'], getline(1, '$'))
  call assert_equal(['qfReviewRead', 'qfFileName'],
        \ [synIDattr(synID(1, 3, 1), 'name'), synIDattr(synID(2, 3, 1), 'name')])
endif
call assert_equal({s:review_head: {'app/model.rb':
      \ trim(system(s:git . ' rev-parse HEAD:app/model.rb'))}},
      \ json_decode(join(readfile(s:repo . '/.review/reviewed.json'))))

" gr lists the files to read, and returns to the full list with new marks.
normal gr
call assert_equal([':Git difftool --name-only base HEAD (to read) — 0/1 read', ['']],
      \ s:review_list())
normal x
normal gr
call assert_equal([':Git difftool --name-only base HEAD — 2/2 read', ['✓', '✓']],
      \ s:review_list())
" A selection of read files is unmarked, then marked again.
execute "normal ggVGx"
call assert_equal(['', ''], s:review_list()[1])
execute "normal ggVGx"
call assert_equal(['✓', '✓'], s:review_list()[1])
cclose

" A new version of a read file is to read again; marks survive new lists.
call writefile(['changed'], s:repo . '/app/extra.rb')
call system(s:git . ' -c user.name=Test -c user.email=test@example.com commit -qam Fourth')
let s:blob = 'fugitive://' . s:repo . '/.git//' . trim(system(s:git . ' rev-parse HEAD')) . '/app/'
let g:config_test_difftool_files = [s:blob . 'model.rb', s:blob . 'extra.rb']
GitReview base HEAD
call assert_equal([':Git difftool --name-only base HEAD — 1/2 read', ['✓', '~']],
      \ s:review_list())
" A three-dot range shares the marks of its merge base.
GitReview base...HEAD
call assert_equal(['✓', '~'], s:review_list()[1])

" Work tree reviews hash the files themselves: the same content from the
" same base is already read, and an edit makes it to read again.
let g:config_test_difftool_files = [s:repo . '/app/model.rb']
GitReview base
call assert_equal(['✓'], s:review_list()[1], 'The same version must stay read')
copen
call writefile(['edited'], s:review_file)
normal gr
call assert_equal(['~'], s:review_list()[1], 'An edited file must be to read again')
normal x
call assert_equal(['✓'], s:review_list()[1])
cclose

" Other lists, such as search results, have no read marks, even when a
" failed difftool leaves them current.
call setqflist([{'filename': s:review_file, 'lnum': 1, 'text': 'match'}])
let g:config_test_difftool_fail = 1
GitReview base
unlet g:config_test_difftool_fail
copen
messages clear
normal x
call assert_match('not a review list', execute('messages'))
call assert_equal(['match'], s:review_list()[1])
cclose

" Filters keep the entries matching fzf's extended search, as new lists that
" keep the review's read marks and return to the full review with gr.
call setqflist([{'filename': s:review_file, 'lnum': 1, 'text': 'match'},
      \ {'filename': s:review_file, 'lnum': 2, 'text': 'other'}])
ReviewFilter other
call assert_equal(['other'], s:review_list()[1], 'Plain lists can be filtered too')
let s:blob = 'fugitive://' . s:repo . '/.git//' . trim(system(s:git . ' rev-parse HEAD')) . '/'
let s:filter_paths = ['app/services/order_sync.rb', 'spec/services/order_sync_spec.rb',
      \ 'app/services/inventory_sync.rb', 'app/models/order.rb']
let g:config_test_difftool_files = map(copy(s:filter_paths), 's:blob . v:val')
function! s:filtered() abort
  return map(getqflist(), 'matchstr(bufname(v:val.bufnr), "//\\x\\+/\\zs.*")')
endfunction
GitReview base HEAD
ReviewFilter service !spec
call assert_equal(['app/services/order_sync.rb', 'app/services/inventory_sync.rb'],
      \ s:filtered())
call assert_match('(filter: service !spec) — 0/2 read$', getqflist({'title': 1}).title)
copen
normal x
call assert_equal(['✓', ''], s:review_list()[1])
ReviewFilter inventory
call assert_equal(['app/services/inventory_sync.rb'], s:filtered())
normal gr
call assert_equal(s:filter_paths, s:filtered(), 'gr must return to the full review')
call assert_equal(['✓', '', '', ''], s:review_list()[1])

" g/ hands the entries to fzf with a diff preview; Enter keeps the matches.
normal g/
let s:fzf = g:config_test_fzf
call assert_equal("1\t✓ app/services/order_sync.rb\tapp/services/order_sync.rb",
      \ s:fzf.source[0])
call assert_match('diff --color=always ' . s:review_head . ' '
      \ . trim(system(s:git . ' rev-parse HEAD')) . ' -- {3}',
      \ s:fzf.options[index(s:fzf.options, '--preview') + 1])
call s:fzf['sink*'](['order', '', s:fzf.source[3], s:fzf.source[0]])
call assert_equal(['app/services/order_sync.rb', 'app/models/order.rb'], s:filtered())
call assert_match('(filter: order) — 1/2 read$', getqflist({'title': 1}).title)
" Ctrl-O opens the entry under the cursor in the review diff.
normal gr
command! -nargs=* Gvdiffsplit let g:config_test_gvdiff = [expand('%:p'), <q-args>]
normal g/
call g:config_test_fzf['sink*'](['', 'ctrl-o', g:config_test_fzf.source[2]])
call assert_equal(s:blob . 'app/services/inventory_sync.rb', bufname('%'))
call assert_equal(4, len(getqflist()), 'Opening must keep the full list')
delcommand Gvdiffsplit
only
cclose

" <CR> in a work tree review opens the file with GitGutter against the
" review's base, on the first hunk, previewed; other lists open entries only.
command! GitGutterAll call gitgutter#all(1)
let s:lines = systemlist(s:git . ' show base:app/model.rb')
let s:lines[2] = 'changed'
call writefile(s:lines, s:review_file)
let g:config_test_difftool_files = [s:repo . '/app/extra.rb', s:repo . '/app/model.rb']
let [g:gitgutter_diff_base, g:gitgutter_async] = ['', 1]
let g:config_test_gitgutter = []
GitReview base
copen
2
execute "normal \<CR>"
call assert_equal(resolve(s:review_file), resolve(expand('%:p')))
call assert_equal([3, s:review_head, 1], [line('.'), g:gitgutter_diff_base, g:gitgutter_async])
call assert_equal([['all', s:review_head, 0], ['preview', 3]], g:config_test_gitgutter,
      \ 'A new base must refresh every buffer synchronously, then preview')
let g:config_test_gitgutter = []
copen
2
execute "normal \<CR>"
call assert_equal([['buffer', s:review_head, 0], ['preview', 3]], g:config_test_gitgutter)
" A file without changes from the base has no hunk to preview.
call writefile(systemlist(s:git . ' show base:app/model.rb'), s:review_file)
edit!
let g:config_test_gitgutter = []
copen
2
execute "normal \<CR>"
call assert_equal(resolve(s:review_file), resolve(expand('%:p')))
call assert_equal([['buffer', s:review_head, 0]], g:config_test_gitgutter)
" Range reviews open blobs, and other lists their entries, without GitGutter.
let g:config_test_gitgutter = []
let g:config_test_difftool_files = [s:blob . 'app/models/order.rb']
GitReview base HEAD
copen
execute "normal \<CR>"
call assert_equal(s:blob . 'app/models/order.rb', bufname('%'))
call setqflist([{'filename': s:review_file, 'lnum': 5, 'text': 'match'}])
copen
execute "normal \<CR>"
call assert_equal([resolve(s:review_file), 5],
      \ [resolve(expand('%:p')), line('.')])
call assert_equal([], g:config_test_gitgutter)
" :ReviewFiles takes over GitGutter's base as it starts.
let [g:gitgutter_diff_base, g:config_test_gitgutter] = ['', []]
ReviewFiles base
call assert_equal([['all', s:review_head, 1]], g:config_test_gitgutter)
only
cclose

" :ReviewCommits lists the commits of the branch, then its uncommitted
" changes; <CR> lists the files of one, and - returns to the commits.
let s:crepo = $VIM_CONFIG_TEST_ROOT . '/commits repo'
let s:cgit = 'git -C ' . shellescape(s:crepo)
function! s:ccommit(day, args) abort
  call system('GIT_AUTHOR_DATE=2026-01-0' . a:day . 'T12:00:00 ' . s:cgit
        \ . ' -c user.name=Test -c user.email=test@example.com commit -q ' . a:args)
endfunction
call mkdir(s:crepo, 'p')
call system('git init -q ' . shellescape(s:crepo))
for s:name in ['a', 'b', 'e']
  call writefile([s:name], s:crepo . '/' . s:name . '.rb')
endfor
call system(s:cgit . ' add .')
call s:ccommit(1, '-m Base')
call system(s:cgit . ' branch -q base')
call writefile(['a2'], s:crepo . '/a.rb')
call s:ccommit(2, "-am 'Change a'")
call writefile(['b2'], s:crepo . '/b.rb')
call writefile(['c'], s:crepo . '/c.rb')
call system(s:cgit . ' add c.rb')
call s:ccommit(3, "-am 'Change b, add c'")
call writefile(['b3'], s:crepo . '/b.rb')
call s:ccommit(4, "-am 'Change b again'")
call writefile(['e2'], s:crepo . '/e.rb')
let s:shas = systemlist(s:cgit . ' rev-list --reverse base..HEAD')
let s:base_sha = trim(system(s:cgit . ' rev-parse base'))
function! s:cblob(rev) abort
  return trim(system(s:cgit . ' rev-parse ' . a:rev))
endfunction
function! s:cstore() abort
  return json_decode(join(readfile(s:crepo . '/.review/reviewed.json')))
endfunction
function! s:marks() abort
  return map(getqflist(), 'v:val.text')
endfunction
" Fugitive's file list for the revisions of the review.
function! ConfigTestRealDifftool(args) abort
  let g:config_test_git_args = a:args
  let l:revs = split(matchstr(a:args, '^difftool --name-only \zs.*'))
  let l:prefix = len(l:revs) == 2
        \ ? 'fugitive://' . s:crepo . '/.git//' . s:cblob(l:revs[1]) . '/' : s:crepo . '/'
  call setqflist([], ' ', {'title': ':Git ' . a:args, 'items': map(systemlist(s:cgit
        \ . ' diff --name-only ' . join(l:revs)), '{"filename": l:prefix . v:val, "text": ""}')})
endfunction
command! -nargs=* Git call ConfigTestRealDifftool(<q-args>)
execute 'cd ' . fnameescape(s:crepo)
let [g:gitgutter_diff_base, g:config_test_gitgutter] = [s:review_head, []]
ReviewCommits base
call assert_equal([['all', '', 1]], g:config_test_gitgutter, 'The commits must reset the base')
call assert_equal([':ReviewCommits base — 0/4 read', 'qf'],
      \ [getqflist({'title': 1}).title, &filetype])
if has('patch-8.2.0959')
  call assert_equal(['      ' . s:shas[0][:6] . ' 2026-01-02 Change a',
        \ '      ' . s:shas[1][:6] . ' 2026-01-03 Change b, add c',
        \ '      ' . s:shas[2][:6] . ' 2026-01-04 Change b again',
        \ '      Uncommitted changes'], getline(1, '$'))
endif
1
call assert_equal(':call gitreview#message()<CR>', maparg(' k', 'n'))
" The popup closes when the cursor moves, as at the end of :normal.
call gitreview#message()
call assert_equal(1, len(popup_list()), '<leader>k must show the message')
call assert_equal(['Change a', ''], getbufline(winbufnr(popup_list()[0]), 1, 2))
call assert_match(' a.rb ', join(getbufline(winbufnr(popup_list()[0]), 1, '$')))
call popup_clear()

" Marks in the files of a commit follow its parent; a file changed by that
" commit only is also read in the files of the branch.
2
execute "normal \<CR>"
call assert_equal('difftool --name-only ' . s:shas[1] . '^ ' . s:shas[1], g:config_test_git_args)
call assert_equal(s:shas[1][:6] . ' 2026-01-03 Change b, add c — 0/2 read',
      \ getqflist({'title': 1}).title)
call assert_equal(['', ''], s:marks())
call gitreview#message()
call assert_equal(1, len(popup_list()))
call assert_equal('Change b, add c', getbufline(winbufnr(popup_list()[0]), 1)[0])
call popup_clear()
2
normal x
call assert_equal({s:shas[0]: {'c.rb': s:cblob(s:shas[1] . ':c.rb')},
      \ s:base_sha: {'c.rb': s:cblob(s:shas[1] . ':c.rb')}}, s:cstore())
normal -
call assert_equal([':ReviewCommits base — 0/4 read', 2, ['', '1/2', '', '']],
      \ [getqflist({'title': 1}).title, line('.'), s:marks()])

" x marks a commit and its files; its patch ID keeps it read when a rebase
" rewrites it.
3
normal x
call assert_equal(['', '1/2', '✓', ''], s:marks())
call assert_equal(':ReviewCommits base — 1/4 read', getqflist({'title': 1}).title)
let s:patch = split(system(s:cgit . ' show ' . s:shas[2] . ' | git patch-id --stable'))[0]
let s:store = s:cstore()
call assert_equal([{s:patch : 1}, {'b.rb': s:cblob(s:shas[2] . ':b.rb')}],
      \ [s:store.commits, s:store[s:shas[1]]], 'b.rb changes twice, so the branch is unmarked')
call assert_false(has_key(s:store[s:base_sha], 'b.rb'))
call remove(s:store, s:shas[1])
call writefile([json_encode(s:store)], s:crepo . '/.review/reviewed.json')
call s:ccommit(4, "--amend -m 'Change b once more'")
let s:shas = systemlist(s:cgit . ' rev-list --reverse base..HEAD')
ReviewCommits base
call assert_equal(['', '1/2', '✓', ''], s:marks())
3
normal x
call assert_equal(['', '1/2', '', ''], s:marks())
call assert_equal({}, s:cstore().commits)
" Unmarking a file of a read commit unmarks the commit.
normal x
execute "normal \<CR>"
normal x
call assert_equal([''], s:marks())
normal -
call assert_equal(['', '1/2', '', ''], s:marks())

" The uncommitted changes are reviewed from HEAD, so their files open with
" GitGutter.
4
execute "normal \<CR>"
call assert_equal(['difftool --name-only HEAD', 'Uncommitted changes — 0/1 read'],
      \ [g:config_test_git_args, getqflist({'title': 1}).title])
normal x
let s:store = s:cstore()
let s:hash = trim(system(s:cgit . ' hash-object e.rb'))
call assert_equal([s:hash, s:hash], [s:store[s:cblob('HEAD')]['e.rb'], s:store[s:base_sha]['e.rb']],
      \ 'Files changed only in the work tree are read in the files of the branch too')
normal -
call assert_equal(['', '1/2', '', '✓'], s:marks())

" gr lists the commits to read, and returns to all of them.
normal gr
call assert_equal([s:shas[0], s:shas[1], s:shas[2]], map(getqflist(), 'v:val.module'))
call assert_match('(to read) — 0/3 read$', getqflist({'title': 1}).title)
normal gr
call assert_equal(4, len(getqflist()))

" The files of the branch show the marks of files changed by one step; the
" first commit shares the merge base with them.
let g:config_test_gitgutter = []
ReviewFiles base
call assert_equal([['all', s:base_sha, 1]], g:config_test_gitgutter)
call assert_equal([s:crepo . '/a.rb', s:crepo . '/b.rb', s:crepo . '/c.rb', s:crepo . '/e.rb'],
      \ map(getqflist(), 'fnamemodify(bufname(v:val.bufnr), ":p")'))
call assert_equal(['', '', '✓', '✓'], s:marks())
copen
1
normal x
" c.rb changes in one commit only, which shares its unmark.
3
normal x
ReviewCommits base
call assert_equal(['✓', '', '', '✓'], s:marks())

" g/ previews commits, and filtered commits still open their files.
normal g/
call assert_equal("2\t      " . s:shas[1][:6] . " 2026-01-03 Change b, add c\t" . s:shas[1],
      \ g:config_test_fzf.source[1])
call assert_match('show --color=always --stat --patch {3}',
      \ g:config_test_fzf.options[index(g:config_test_fzf.options, '--preview') + 1])
ReviewFilter 'more
call assert_equal([s:shas[2]], map(getqflist(), 'v:val.module'))
" gc on a commit is <CR>, so - returns to it.
normal gc
call assert_equal('difftool --name-only ' . s:shas[2] . '^ ' . s:shas[2], g:config_test_git_args)
normal -
call assert_equal([s:shas[2]], map(getqflist(), 'v:val.module'))

" - keeps its usual motion in other lists.
call setqflist([{'filename': 'a.rb', 'lnum': 1}, {'filename': 'b.rb', 'lnum': 1}])
copen
2
normal -
call assert_equal(1, line('.'))
delcommand Git
delcommand GitGutterAll
only
cclose
execute 'cd ' . fnameescape(s:cwd)

call writefile(['{"annotations": '], s:review_json)
call assert_equal(1, reviewcontext#annotation(s:review_file, 4).error)
call writefile(['[]'], s:review_json)
call assert_equal(1, reviewcontext#annotation(s:review_file, 4).error)
call delete(s:review_json)
call assert_equal(0, reviewcontext#annotation(s:review_file, 4).error)

" Source deferred implementations too, without invoking external programs.
" Earlier steps run Vim's own ftplugins, whose cleanup may set v:errmsg.
let v:errmsg = ''
for s:script in glob(s:runtime . '/autoload/*.vim', 0, 1)
  execute 'source ' . fnameescape(s:script)
endfor
call assert_equal('', v:errmsg)
if !empty(v:errors)
  for s:error in v:errors
    echomsg s:error
  endfor
  cquit
endif
qa!
