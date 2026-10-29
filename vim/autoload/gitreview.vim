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

function! gitreview#qf_commit() abort
  let item = getqflist()[line('.') - 1]
  let commit = item.module

  if empty(commit)
    echoerr 'No commit on this quickfix entry'
    return
  endif

  execute 'GitReview ' . commit . '^ ' . commit
endfunction
