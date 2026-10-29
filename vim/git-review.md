# Git review shortcuts

```text
Review uncommited work
:Git
From here:
=       toggle inline diff
]c      next hunk
[c      previous hunk
]m      next changed file
[m      previous changed file
dv      vertical side-by-side diff
dq      close the diff view
-       stage or unstage file/hunk

Review the last commit
:Git show --stat HEAD
:Git show HEAD
For a systematic source-level review:
:Git difftool HEAD^ HEAD
Navigate with:
:cnext
:cprevious
:copen
For a full side-by-side review, one file per tab:
:Git difftool -y HEAD^ HEAD
Then :
]c / [c       next/previous hunk
gt / gT       next/previous file tab
<C-w>w        switch diff side
dq            close current diff

Review the entire current branch
:Git fetch origin
Inspect the commits belonging to your branch:
:Git log --oneline --decorate origin/staging..HEAD
Inspect its size:
:Git diff --stat origin/staging...HEAD
Then review every hunk:
:Git difftool origin/staging...HEAD
For side-by-side tabs:
:Git difftool -y origin/staging...HEAD

Deep-review one particular file
While editing the file:
:Gvdiffsplit origin/staging...HEAD
For the last commit:
:Gvdiffsplit HEAD^
For the current committed version:
:Gvdiffsplit HEAD
For ordinary unstaged changes:
:Gvdiffsplit

GitGutter based review:
Review diff main
:Review
Review diff last commit
:ReviewLast
Reset to default GitGutter
ReviewEnd

:Git difftool --name-only main
Then in quickfix gd to open diff split
```
