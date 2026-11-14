# Review methods

Every way to review code that this repository implements or configures,
from a quick look at local changes to a full GitLab merge request. Commands
marked *(plugin)* come from a plugin installed by the vimrc; everything else is
defined here. Step-by-step Fugitive walkthroughs are in
[vim/git-review.md](vim/git-review.md); GitLab endpoint details are in
[vim/README.md](vim/README.md#gitlab-reviews-in-vim).

## Choosing a method

| To review | Use |
| --- | --- |
| Uncommitted work | `:Git`, then `=` / `dv` on files |
| Staged changes before committing | `gdca`, `rubs` |
| The last commit | `:ReviewLast`, or `:GitReview HEAD^ HEAD` |
| The current branch against main | `:Review`, or `:GitReview origin/main...HEAD` |
| Any two commits or branches | `:GitReview <left> <right>` |
| A GitLab merge request | `:MR`, `:MR mine`, `:MR merged` |
| One file in depth | `:Gvdiffsplit <rev>` |
| A specific piece of code | `:AgentExplain` on a line or range |
| Ruby style of a change | `rubo`, `rubo <n>`, `rubs` |

## Vim

### GitGutter review: `:Review`, `:ReviewLast`, `:ReviewEnd`

Shows a diff base in the sign column of every buffer and lists every hunk in
quickfix. Navigate with `:cnext` / `:cprevious`.

| Command | Diff base |
| --- | --- |
| `:Review` | Merge base of `HEAD` and `origin/main` |
| `:Review <ref>` | Merge base of `HEAD` and `<ref>`, such as `origin/staging` |
| `:ReviewLast` | `HEAD^`: the last commit plus uncommitted changes |
| `:ReviewEnd` | Restores GitGutter's default base and closes quickfix |

Using the merge base shows only the branch's own changes, not what landed on
the target since the branch started. Run `:ReviewEnd` when done: the base
stays in effect for every buffer until then.

### File-by-file diff review: `:GitReview`

`:GitReview <left> [<right>]` lists the changed files in quickfix with
`:Git difftool --name-only`. In the quickfix window:

| Key | Action |
| --- | --- |
| `gd` | Open the entry as a vertical diff against `<left>`, quickfix below |
| `gc` | Start a `:GitReview` of the entry's commit (`<commit>^ <commit>`) |

Examples:

```vim
:GitReview HEAD                  " working tree against HEAD
:GitReview HEAD^ HEAD            " the last commit
:GitReview origin/main...HEAD    " the branch since it left main
```

`gc` works on quickfix entries that carry a commit, such as those from
`:Gclog` or the `:MR` original-commit list. Only the most recently started
review drives `gd` and `gc`.

### GitLab merge requests: `:MR`

| Command | Lists |
| --- | --- |
| `:MR` | Open MRs in the current project |
| `:MR mine` | Open MRs with you as a reviewer |
| `:MR merged` | Merged MRs, newest first |

In the selector: `<CR>` opens the full MR diff in a new tab, `c` lists the
original commits, `o` opens the MR in the browser, `r` refreshes, `n` / `p`
page, and `q` closes. Each review then uses the `gd` / `gc` quickfix
workflow above. Missing objects are fetched under `refs/vim-mr/` without
touching the checkout. Requires `glab` to be authenticated.

### Fugitive *(plugin)*

| Command | Purpose |
| --- | --- |
| `:Git` | Status window: `=` inline diff, `dv` side-by-side, `-` stage, `]c` / `[c` hunks |
| `:Git show HEAD` | Read a commit |
| `:Git difftool <range>` | Every hunk of a range in quickfix |
| `:Git difftool -y <range>` | One side-by-side tab per file (`tabpagemax` is 100 for this) |
| `:Gvdiffsplit [<rev>]` | Deep-review the current file against a revision |
| `:Gclog [<range>]` | Commits in quickfix; `gc` reviews one |
| `:Git blame` | Who changed each line, and in which commit |
| `:GBrowse` | Open the file or selection on GitHub or GitLab, including `gitlab.myjungly.com` |

### Other Vim helpers

- `:Commits` and `:BCommits` *(plugin, fzf.vim)*: browse the project's or the
  current file's commits with a diff preview.
- `:Linediff` *(plugin)*: select a block, run `:Linediff`, then do the same on
  a second block to compare two pieces of code, even within one file.
- `:AgentExplain`: send the current line, a Visual selection, or a range
  (`:10,25AgentExplain`) to an agent in another tmux pane for an explanation.
  `:AgentSelectPane` chooses the pane.
- `REVIEW`, `TODO`, `FIXME`, `BUG`, `HACK`, and `NOTE` are highlighted in every
  window, as are `BROKEN`, `WTF`, and `DONE`, which helps when leaving review
  notes in code.
- The Fern drawer *(plugin)* shows the Git status of files in the tree.

Vim's diff mode (`:Gvdiffsplit`, `gd`, `:Git difftool -y`) ignores whitespace
changes (`diffopt+=iwhite`). Check indentation-only changes with `git diff`
or GitGutter.

## Shell

### Git aliases (`zsh/aliases.zsh`, `gitconfig`)

| Command | Purpose |
| --- | --- |
| `gd` | `git diff`: unstaged changes |
| `gdca` | `git diff --cached`: staged changes |
| `glo`, `gld` | One-line log, with relative dates for `gld` |
| `gla`, `glb` | Graph of all branches, compact or detailed |
| `git merged [<target>]` | Fetch, then say whether `HEAD` is merged into `origin/<target>` (default `main`) |

Pagers and `git add -p` use `diffr`, which highlights the changed words
within each line.

### Functions (`zsh/functions.zsh`)

| Command | Purpose |
| --- | --- |
| `rubo` | RuboCop (Rails) on Ruby files changed in the working tree |
| `rubo <n>` | RuboCop on Ruby files added or modified in the last `<n>` commits |
| `rubs` | RuboCop on staged Ruby files |
| `rubsa` | Same as `rubs`, with auto-correct (modifies the files) |
| `list-contrib-branch` | Merges into main, staging, or master that contain your commits |
| `git-list-mj` | Branches of each `mj-fleet-backend` clone, with dirty state |

### Tig

In the main and diff views, `R` starts `git rebase -i` from the selected
commit, to clean up history before asking for a review.
