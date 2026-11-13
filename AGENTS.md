# Repository guidance

This repository contains personal Linux dotfiles for Vim, Zsh, tmux,
Alacritty, Git, and development tools. There is no application build step.

## Layout

- `vimrc`: the whole Vim configuration, in folded sections.
- `vim/`: Vim runtime files, snippets, documentation, and offline tests.
  Read `vim/README.md` before changing the configuration structure.
- `zshrc`, `profile`, `zsh/`: shell startup, aliases, functions, and prompt.
- `tmux.conf`, `tmuxinator/`: tmux settings and project session definitions.
- `alacritty.toml`: terminal settings.
- `gitconfig`, `gitignore`, `tigrc`: Git and Tig configuration.
- `pryrc`, `rubocop.yml`, `gdbinit`, `inputrc`: development tool settings.
- `link.sh`: creates live configuration symlinks from `~/code/dotfiles`.

## Conventions

- Write documentation, comments, user-facing messages, and commits in English.
- Preserve personal key bindings, command names, paths, and integrations unless
  the requested change concerns them. Keep changes focused on the task.
- Use the existing tools and configuration languages. Vim configuration uses
  classic Vimscript and vim-plug; preserve compatibility with classic Vim.
- Match surrounding formatting: Vimscript generally uses two-space indentation;
  Python tests use four spaces. Snippet bodies require literal tabs.
- Keep documentation aligned with changed commands, setup, or behavior.
- Leave editor swap files (`.swp`, `.swo`, and similar files) untouched and out
  of commits. Keep private Git settings in `~/.gitconfig.local`.

## Vim structure

- Keep the configuration in the single `vimrc`, organized in marker folds
  (`{{{1` sections, `{{{2` subsections). Put only substantial implementations
  in `vim/autoload/`; do not reintroduce `vim/config/`, `vim/plugin/`,
  `vim/ftdetect/`, or `vim/after/ftplugin/` files.
- Set plugin startup variables before `plug#end()` and colorscheme variables
  before selecting the colorscheme.
- Match autoload function namespaces to their paths, such as `glow#open()` in
  `vim/autoload/glow.vim`. Keep helpers script-local when possible.
- Preserve existing public commands and compatibility functions. The MR
  selector calls `GitReview()`; quickfix review mappings use `GitQfDiff()` and
  `GitQfReviewCommit()`.
- Put filename detection in the vimrc's `dotfiles_filetypes` group. Put
  filetype preferences in an `s:ft_<filetype>()` function in the vimrc's
  Filetypes section, using `setlocal`, `<buffer>` mappings, and
  `s:undo_ftplugin()` cleanup. Use `vim/after/indent/` or `vim/after/syntax/`
  only for overrides that need those scripts to have finished loading.
- Keep reloads safe: use named autocommand groups with `autocmd!`, avoid
  duplicate runtime paths and highlights, and guard repeated filetype setup.
- Keep snippets in `vim/snippets/`; Vim's runtime path discovers them.
  New runtime files do not require individual symlinks in `link.sh`.
- Preserve the Ruby cached-tags workaround and native tag-stack behavior.
- GitLab reviews use recorded commit endpoints, including the merge commit's
  first parent. Fetch missing objects into `refs/vim-mr/` without modifying
  HEAD, the index, the working tree, `FETCH_HEAD`, or ordinary remote-tracking
  refs. Preserve original-history errors when squash objects are unavailable.

## Validation

Run checks from the repository root, choosing those relevant to the change:

```sh
git diff --check
bash -n link.sh
sh -n profile
python3 vim/tests/run_config.py
python3 vim/tests/run_gitmr.py
```

- For Zsh changes, syntax-check each changed file with `zsh -n path/to/file`
  when Zsh is available. Do not source startup files just to check syntax.
- The configuration runner checks startup, reloads, and filetype isolation
  using temporary plugin stubs. The MR runner uses temporary Git repositories
  and a fake glab API; it does not need GitLab credentials.
- Both Vim runners return 77 when Vim is unavailable. Report skips explicitly;
  passing Git fixture checks alone does not validate Vimscript execution.
  `VIM_CONFIG_VIM` and `GITMR_VIM` can select another Vim executable.
- Add regression coverage for changed behavior using these runners when
  appropriate. Documentation-only edits need no new tests.
- Do not run `link.sh` as a validation step: it replaces live home-directory
  symlinks. Review installer changes with syntax checks and inspect their
  targets. Keep downloaded plugins and machine-local state outside the repo.

## Commit messages

Use Tim Pope's style: an imperative, capitalized subject of at most 50
characters with no trailing period. Separate an optional body with a blank
line, wrap it at 72 characters, and explain the reason for the change.
