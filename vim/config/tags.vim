" Keep generated tag files outside repositories.
let g:gutentags_cache_dir = expand('~/.cache/vim/gutentags')

" Explicitly use Universal Ctags.
let g:gutentags_ctags_executable = 'ctags'

" Let Git decide which files belong to the project:
"   -c: tracked files
"   -o: untracked files
"   --exclude-standard: respect .gitignore, .git/info/exclude and global ignore
let g:gutentags_file_list_command = {
      \ 'markers': {
      \   '.git': 'git ls-files -co --exclude-standard'
      \ }
      \ }

" Generate qualified entries such as namespaced classes and scoped methods.
let g:gutentags_ctags_extra_args = ['--extras=+q', '--fields=+nKS']

" Useful if some generated directories contain tracked files.
let g:gutentags_ctags_exclude = [
      \ 'log/*',
      \ 'tmp/*',
      \ 'storage/*',
      \ 'coverage/*',
      \ 'node_modules/*',
      \ 'vendor/*',
      \ 'public/assets/*',
      \ 'public/packs/*'
      \ ]

" These are defaults, but keeping them explicit documents the behaviour.
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_background_update = 1

" Optional status-line indicator while ctags is running.
let s:status = "%{gutentags#statusline('[',']')}"
if stridx(&statusline, s:status) < 0
  let &statusline .= s:status
endif

" Jump immediately when unique; show the selection list when ambiguous.
" nnoremap <C-]> g<C-]>

" Open in new tab
nnoremap <leader>] :tab tag <C-R><C-W><CR>

" Open in new split
nnoremap <leader>[ :stag <C-R><C-W><CR>

" Useful native commands:
" CTRL-]          Jump to definition; mapped above
" g]              Always show all matching tags
" CTRL-T          Return through the tag stack
" :tags           Display the current tag stack
" :tnext          Next matching tag
" :tprevious      Previous matching tag
" CTRL-W g CTRL-] Open the definition in a split
"
" Vim maintains a real tag stack, so CTRL-T is preferable to relying exclusively on CTRL-O
"
" A Normal workflow would be:
"
" CTRL-]       Symbol directly under cursor
" g]           Inspect ambiguous definitions
" :Tags Foo    Search for an approximately known class or method
" :BTags       Browse the structure of a large current file
" CTRL-T       Return
