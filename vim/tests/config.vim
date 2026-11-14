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
      \ 'GitReview', 'MR', 'Tabs', 'Glow', 'Today', 'OpenSpec']
  call assert_equal(2, exists(':' . s:command), s:command)
endfor
for s:function in ['ReviewGitGutter', 'GitReview', 'GitQfDiff',
      \ 'GitQfReviewCommit', 'Glow', 'Tabs', 'Today', 'OpenRubyAPI',
      \ 'OpenCorrespondingSpec']
  call assert_true(exists('*' . s:function), s:function)
endfor
for s:function in ['gitreview#open', 'glow#open', 'navigation#tabs', 'rubytools#api']
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
AgentExplain
call assert_equal([['list-panes']], map(s:tmux_calls(), 'v:val.args[:0]'))
call assert_false(exists('g:agent_pane'))
let $TMUX = ''
AgentExplain
call assert_equal([], s:tmux_calls(), 'tmux must not be used outside tmux')
bwipeout!

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
