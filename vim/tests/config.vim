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
      \ 'ReviewContext', 'ReviewContextList', 'ReviewContextMarks', 'ReviewSummary']
  call assert_equal(2, exists(':' . s:command), s:command)
endfor
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
bwipeout!

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
