dotfiles
========

`link.sh` links `vifmrc` to `~/.config/vifm/vifmrc`. It sets Vim as the
editor, shows hidden files, and enables absolute and relative line numbers.

`link.sh` links `ignore` to `~/.ignore`. rg and fd read it as a parent
`.ignore` file, so searches under `$HOME` skip `.git/`, `node_modules/`, and
`target/`. This covers the fzf `Ctrl-T` and `Alt-C` widgets and Vim's fzf
commands. Searches outside `$HOME` do not use it.
