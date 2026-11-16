# Vim configuration

`../vimrc` holds the whole configuration in one file, split into folded
sections: Options, Plugins (with Gutentags and Rails projections), Appearance,
Mappings, Autocommands, Filetypes, Commands, and the project override. `zM`
closes every section and `za` toggles the one under the cursor. The vimrc
resolves its symlink and adds this directory and `after/` to Vim's
`runtimepath`. Keep `~/.vim` for vim-plug, downloaded plugins, and local state.

Only files that cannot live in the vimrc remain here:

| Location | Responsibility |
| --- | --- |
| `autoload/` | Custom feature implementations, loaded on first use |
| `after/indent/` | Overrides that must run after indent scripts |
| `after/syntax/` | Extra syntax rules |
| `snippets/` | Personal SnipMate snippets |
| `tests/` | Offline configuration and GitLab MR checks |

Set plugin startup variables before `plug#end()`; keep colorscheme variables
before `colorscheme`. Public commands and compatibility functions are defined
in the Commands section, before `.vim.custom`, so the project override can use
them. Substantial implementations stay in `autoload/`.

Filetype settings are `s:ft_<filetype>()` functions in the Filetypes section.
One `FileType` handler, defined after `filetype plugin on`, runs them after
Vim's own filetype plugins, like `after/ftplugin/` scripts. They use
`setlocal`, buffer mappings, and `b:undo_ftplugin`, so switching filetypes
cleans up their settings. The Ruby tag workaround and quickfix `gd`/`gc` review
mappings are preserved. Custom filename detection is in the
`dotfiles_filetypes` group. YAML's `indentkeys` override lives in
`after/indent/` because the default indent script sets that option after
filetype plugins have run.

Installation still uses `../link.sh`, which links only the vimrc. Old links to
the removed `after/ftplugin/ruby.vim` are harmless and can be deleted. Restart
Vim after updating; `:source $MYVIMRC` reloads preferences during normal use.
Already loaded autoload implementations require a restart to pick up edits.

Plugin installation and prerequisites are unchanged: vim-plug and the listed
plugins must already be installed. [review.md](../review.md) lists every
review method in the repository, with Git review command examples.

The leader key is Space, defined before plugins and mappings. Use `Space f b`
for Buffers and `Space f h` for History; Ruby's block toggle stays on `Space b`
and hash conversions on `Space h c`, `Space h h`, and `Space h r`. The build
shortcut is `Space 5` in Normal mode and `\5` in Insert mode, so ordinary
spaces do not trigger or delay a mapping while typing. Restart Vim after
changing the leader to discard bindings defined with the old leader.

Run configuration checks with `python3 vim/tests/run_config.py` from the
repository root. They use temporary directories and stubs for vim-plug and
Gruvbox, with no plugin downloads. Run MR integration checks with
`python3 vim/tests/run_gitmr.py`. Both runners return 77 if Vim is unavailable.

## Preview colors

Vim uses Gruvbox with a light cream background. The fzf interface and preview
background follow Vim's highlight groups; file previews use bat's bundled
`gruvbox-light` theme (`bat` or `batcat` must be installed for syntax colors).
This applies to `:Files`/`<C-P>` and `:Rg` as well as other fzf.vim pickers.
In zsh, fzf uses its light palette and bat uses the same `gruvbox-light` theme.
Inside tmux, Vim sets the true-color escape codes that it only enables by
default for xterm-like terminals.

## Agent explanations

`:AgentExplain` sends the current line, relative file path, and line numbers
as an explanation prompt to the selected tmux pane, then submits it with Enter.
On first use, it asks you to select a pane from the current tmux window, other
than Vim's own, and remembers the target in `g:agent_pane`. Run
`:AgentSelectPane` to change it; canceling the selection leaves the existing
target unchanged.
Select code in Visual mode and run `:AgentExplain` to send the selected lines,
or use an explicit range such as `:10,25AgentExplain`. Vim must run inside tmux,
on the same server as the agent. The prompt goes through a temporary
`vim-agent` tmux buffer, so the paste stack is left as it was, and uses
bracketed paste so its newlines do not submit it early. If loading or pasting
the buffer fails, the command reports the tmux error and stops before sending
Enter.

## Review context

`:ReviewContext`, or `<leader>k`, shows in a popup the review annotation that
covers the cursor line, read from `.review/context.json` at the root of the
current file's Git repository. That file is typically written by an agent
that analyzed the change. When several ranges cover the line, the narrowest
one wins. Press `q` or `Esc`, or move the cursor, to close the popup. It
requires Vim with `+popupwin`.

Lines where annotations start are marked after their text, such as
`◆ 2 risks` or `◆ review`, as soon as a file of a repository with a review
context is opened. Marks follow edits and refresh when the context is
regenerated. `:ReviewContextMarks` turns them off or on everywhere. Before
Vim 9.1, or with `g:review_context_signs` set, they use the sign column
instead, below GitGutter's priority. Both use the `ReviewContextMark`
highlight group, linked to `Special` by default.

Fugitive buffers, such as the blobs that `gd` opens after
`:GitReview origin/main...HEAD` or `:MR`, count as their working-tree file
when their content is the same, as for `HEAD` without local changes.
`:ReviewFiles` opens the working-tree files themselves. Another version,
such as an intermediate commit in `:ReviewCommits` or the merge base in the
left diff window, gets the annotations mapped through `git diff` to the
working tree. Code that later changes leave alone keeps exact marks and
popups. Annotations whose lines change later have hollow marks, such as
`◇ 2 risks`, and their popup warns that the notes describe the final code.
Annotations of code added later do not appear. Without Git, another
version gets no marks, and its popup warns that its lines differ.

`:ReviewContextList` puts every annotation of the repository in the location
list, sorted by file and line with enclosing ranges first, showing the
symbol, kind, number of risks, and the first line of the summary.

```json
{"base": "<merge-base sha>", "head": "<HEAD sha>",
 "annotations": [
  {"path": "app/models/user.rb", "start": 10, "end": 24,
   "symbol": "User#save", "kind": "method", "summary": "What the code does",
   "change": "What the change does", "risks": ["What could break"]}
]}
```

Paths are relative to the repository root, and line ranges are inclusive
integers. Only `path`, `start`, and `end` are required; malformed entries,
string line numbers, and non-string risks are skipped. The title shows
`symbol (kind)`.

The ranges describe the files as they were when the review was generated.
The popup warns that they may be stale when `HEAD` no longer matches `head`
(a full or abbreviated hash), when the file is newer than `context.json`, or
when the buffer has unsaved changes. Generate the review again in those
cases.

## Review summary

`:ReviewSummary`, or `<leader>K`, opens in a new tab a pre-reading of the
whole change, from the optional `summary` object of `.review/context.json`:
its intent, goals and non-goals, the contract, a reading order, tests, risks,
and questions for the author. The contract lists what callers, users, and
other teams can rely on after the merge, breaking changes first, then
changes, then explicit guarantees that something stays the same.

On a contract item or reading-order step with a file reference, `<CR>` opens
the code beside the summary and reuses that window for later references;
`q` closes the summary. The header shows the commits of the review and warns
when `HEAD` moved or referenced files changed after it was generated.

```json
"summary": {
  "intent": "Why the branch exists",
  "goals": ["What the change commits to"],
  "non_goals": ["What it deliberately leaves out"],
  "contract": [
    {"text": "What callers can rely on", "status": "changed",
     "ref": {"path": "app/services/order_sync.rb", "start": 20}}
  ],
  "reading_order": [
    {"path": "app/services/inventory_sync.rb", "start": 1, "why": "Where to start"}
  ],
  "tests": ["What is covered or missing"],
  "risks": ["What could break"],
  "questions": ["What to ask the author"]
}
```

`status` is `breaking`, `changed`, or `unchanged`, and `ref` is optional.
Reading-order steps need `path` and `start`. Every field is optional;
malformed entries are skipped.

## Markdown preview

`:Glow` renders the current buffer in a new tab with absolute line numbers for
the rendered output. Glow's width excludes the number column, and long lines
wrap to stay visible when the window is narrowed. Its light/dark style follows
Vim's `background` setting. Press `q` to close the preview.

## GitLab reviews in Vim

The selector uses classic Vim with `+job`, `json_decode()`, `glab`, and the
`GitReview` defined in the vimrc's Commands section. The vimrc also adds the implementations to the runtime; no individual autoload symlink or
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
the usual workflow (`gd` for files, `gc` for a commit, `x` to mark a file
as read, `gr` for the files to read, `g/` to filter them with fzf). Closing
only the
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
