# Vim configuration

`../vimrc` is the entry point. It resolves its symlink and adds this directory
and `after/` to Vim's `runtimepath`, so new runtime files need no installer
changes. Keep `~/.vim` for vim-plug, downloaded plugins, and local state.

| Location | Responsibility |
| --- | --- |
| `config/options.vim` | General editor defaults |
| `config/plugins.vim` | vim-plug declarations and plugin startup variables |
| `config/rails.vim`, `config/tags.vim` | Larger Rails and Gutentags configurations |
| `config/appearance.vim` | Colorscheme and display preferences |
| `config/mappings.vim` | General editing and plugin shortcut mappings |
| `config/autocmds.vim` | General events, in groups safe to reload |
| `plugin/` | Public commands and compatibility functions |
| `autoload/` | Custom feature implementations, loaded on first use |
| `ftdetect/` | Custom filename-to-filetype rules |
| `after/ftplugin/` | Filetype settings and buffer mappings |
| `after/indent/` | Overrides that must run after indent scripts |
| `after/syntax/` | Extra syntax rules |
| `snippets/` | Personal SnipMate snippets |
| `tests/` | Offline configuration and GitLab MR checks |

The entry point loads options, then plugin configuration, then enables filetype
plugins and syntax. Appearance, general mappings, and events follow. Personal
command entry points load before `.vim.custom`, preserving the ability to use
those commands from the existing project override. The implementations stay
in `autoload/`. Set plugin startup variables before `plug#end()`; keep
colorscheme variables before `colorscheme`.

Filetype overrides use `setlocal`, buffer mappings, and `b:undo_ftplugin` so
switching filetypes cleans up their settings. Ruby hash conversions and folding
are now local to Ruby; Rust's `<C-s>`, Go's whitespace display, and C's compiler
error format no longer affect unrelated buffers. The Ruby tag workaround and
quickfix `gd`/`gc` review mappings are preserved. YAML's `indentkeys` override
lives in `after/indent/` because the default indent script sets that option
after filetype plugins have run.

Installation still uses `../link.sh`. It links the entry point; runtime files
and snippets no longer need individual symlinks. Existing Ruby/autoload links
can remain: filetype guards prevent applying the Ruby overrides twice. Restart
Vim after updating; `:source $MYVIMRC` reloads preferences during normal use.
Already loaded autoload implementations require a restart to pick up edits.

Plugin installation and prerequisites are unchanged: vim-plug and the listed
plugins must already be installed. Git review command examples are in
[git-review.md](git-review.md).

Run configuration checks with `python3 vim/tests/run_config.py` from the
repository root. They use temporary directories and stubs for vim-plug and
Gruvbox, with no plugin downloads. Run MR integration checks with
`python3 vim/tests/run_gitmr.py`. Both runners return 77 if Vim is unavailable.

## GitLab reviews in Vim

The selector uses classic Vim with `+job`, `json_decode()`, `glab`, and the
`GitReview` defined in `plugin/gitreview.vim`. The vimrc loads this entry point
and adds the implementations to the runtime; no individual autoload symlink or
additional plugin is needed.

| Command | List |
| --- | --- |
| `:MR` | Open MRs in the current GitLab project |
| `:MR merged` | Merged MRs, newest first by `merged_at` |
| `:MR mine` | Open MRs with the authenticated user as a reviewer |

In the buffer, use `j/k` to navigate, `<CR>` for the full diff, `c` for the
original commits, `o` to open the browser, `r` to refresh, `n/p` for pages of
100 MRs, and `q` to close. The list preserves the existing quickfix list.
Each review opens a new tab and closes the selector; quickfix then follows
the usual workflow (`gd` for files, `gc` for a commit). Closing only the
selector preserves the other windows and the quickfix list.

## Review endpoints

| Situation | Full diff (`<CR>`) |
| --- | --- |
| Open MR | `diff_refs.base_sha` → `diff_refs.head_sha` |
| Standard merge, including squash followed by merge | First parent of `merge_commit_sha` → merge commit |
| Squash without a merge commit | Parent of `squash_commit_sha` → squash commit |
| Fast-forward without squash | `diff_refs.base_sha` → `diff_refs.head_sha` |

The merge's first parent is the target **at the time of the merge**: the diff
includes conflict resolutions and excludes unrelated target changes.
Original commits (`c`) use only `diff_refs` and
`:Gclog! --reverse base..head`. If their objects can no longer be fetched after
a squash, a message suggests using the final diff; the squash is never
presented as reconstructed original history.

`glab api` requests use the repository and authentication configured in glab
(`projects/:fullpath` and `:username`, supported in the
[glab 1.53.0 source](https://gitlab.com/gitlab-org/cli/-/blob/v1.53.0/commands/api/api.go)).
Fetching prefers an existing remote matching the project identified by glab,
preserving its transport; otherwise it uses the project URL. It fetches the
required SHAs, then the MR HEAD and target branch if needed, exclusively under
`refs/vim-mr/<project>/<iid>/`. The fetched target makes historical objects
accessible and never replaces the comparison endpoints.
There is no checkout, reset, pull, or write to the index or working tree.
`FETCH_HEAD` and ordinary remote-tracking branches remain unchanged.

Network operations are asynchronous, and closing the selector cancels the
current job. glab/Git errors remain visible below the list. For GitLab versions
before 17.2, which cannot
[sort by `merged_at`](https://docs.gitlab.com/api/merge_requests/#list-project-merge-requests),
the selector loads all merged MR pages and sorts them; this can take time on
a large project.

Limitations: working glab/Git authentication is still required. If objects have
disappeared from the server, metadata alone cannot recreate their contents.
A shallow clone may need to be deepened explicitly; the selector does not
fabricate its history. The existing `GitReview` global endpoints refer to the
most recently started review: finish one review before opening another to use
its `gd/gc` mappings.

## Offline tests

```sh
python3 vim/tests/run_gitmr.py
```

The script creates temporary repositories and a fake glab API. It checks
merges with conflict resolution, squash, squash followed by merge, multi-commit
fast-forward, deleted source branches, unavailable original history, shallow
clones, targeted fetching from a clone with staged/unstaged changes, sorting
across pages, reviewers, refresh, errors, and cancellation. Endpoint assertions
execute the Vimscript directly; Fugitive is stubbed only at the review UI
boundary. The script returns 77 if Vim is not installed.
