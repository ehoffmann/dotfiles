" Public Git review API, including the entry point used by gitmr.
if exists('g:loaded_dotfiles_gitreview')
  finish
endif
let g:loaded_dotfiles_gitreview = 1

let g:git_review_left = get(g:, 'git_review_left', '')
let g:git_review_right = get(g:, 'git_review_right', '')

function! ReviewGitGutter(base) abort
  return gitreview#gutter(a:base)
endfunction

function! GitReview(...) abort
  return call('gitreview#open', a:000)
endfunction

function! GitQfDiff() abort
  return gitreview#qf_diff()
endfunction

function! GitQfReviewCommit() abort
  return gitreview#qf_commit()
endfunction

command! -nargs=? Review
      \ call ReviewGitGutter(empty(<q-args>) ? 'origin/main' : <q-args>)

command! ReviewLast
      \ let g:gitgutter_diff_base = 'HEAD^' |
      \ GitGutterAll |
      \ GitGutterQuickFix |
      \ copen

command! ReviewEnd
      \ let g:gitgutter_diff_base = '' |
      \ GitGutterAll |
      \ cclose

command! -nargs=+ GitReview call GitReview(<f-args>)

" GitLab MR selector; reuses GitReview and after/ftplugin/qf.vim mappings.
if exists(':GitMRs') == 2
  delcommand GitMRs
endif
command! -nargs=? -complete=customlist,gitmr#complete MR call gitmr#open(<q-args>)
