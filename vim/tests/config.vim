set nomore
let s:runtime = $VIM_CONFIG_TEST_RUNTIME

" Exercise the normal startup entry point, including project overrides.
call assert_equal('', v:errmsg)
call assert_equal('gruvbox', g:colors_name)
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
call assert_true(index(globpath(&runtimepath, 'snippets/_.snippets', 0, 1),
      \ s:runtime . '/snippets/_.snippets') >= 0)
let s:paths = globpath(&runtimepath, 'ftdetect/custom.vim', 0, 1)
let s:statusline = &statusline
let g:git_review_left = 'keep-review-state'
source $MYVIMRC
call assert_equal('', v:errmsg)
call assert_equal(s:paths, globpath(&runtimepath, 'ftdetect/custom.vim', 0, 1))
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
  call assert_equal(1, maparg('\' . s:key, 'n', 0, 1).buffer)
endfor
call assert_match('lib/', &l:path)
setlocal filetype=text
call assert_equal('', maparg('\hc', 'n'))
call assert_equal('', maparg('<C-]>', 'n'))
call assert_false(exists('b:dotfiles_ruby_settings'))
setlocal filetype=ruby
call assert_equal(1, maparg('\hc', 'n', 0, 1).buffer)

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

" Source deferred implementations too, without invoking external programs.
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
