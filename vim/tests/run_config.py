#!/usr/bin/env python3
"""Check real Vim startup and filetype isolation without downloading plugins."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


PLUG_STUB = """function! plug#begin(...) abort
  let g:config_test_plugins = []
  command! -nargs=+ Plug call add(g:config_test_plugins, <args>)
endfunction

function! plug#end() abort
  call assert_equal(['ctags'], g:gutentags_modules)
  call assert_equal(1, g:fern#default_hidden)
  call assert_equal(1, g:snipMate.snippet_version)
  call assert_true(exists('g:rails_projections'))
  filetype plugin indent on
endfunction
"""

GLOW_STUB = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

Path(os.environ['VIM_CONFIG_TEST_GLOW_ARGS']).write_text(json.dumps(sys.argv[1:]))
width = int(sys.argv[sys.argv.index('-w') + 1])
print('x' * width)
print('y' * (width * 2))
"""

TMUX_STUB = """#!/usr/bin/env python3
import json
import os
import sys

args = sys.argv[1:]
call = {'args': args}
if args[0] == 'load-buffer':
    call['stdin'] = sys.stdin.read()
with open(os.environ['VIM_CONFIG_TEST_TMUX_LOG'], 'a') as log:
    log.write(json.dumps(call) + '\\n')
if args[0] == os.environ.get('VIM_CONFIG_TEST_TMUX_FAIL'):
    print("can't find pane", file=sys.stderr)
    sys.exit(1)
if args[0] == 'list-panes':
    print(os.environ['TMUX_PANE'] + ' 0 vim')
"""

# Enough of fzf --filter for the quickfix filter: fuzzy terms, 'exact terms,
# and !excluded terms, matched case-insensitively against one field.
FZF_STUB = r"""#!/usr/bin/env python3
import sys

args = dict(arg[2:].split('=', 1) for arg in sys.argv[1:] if '=' in arg)
field = int(args.get('nth', '0')) - 1

def fuzzy(term, text):
    position = 0
    for char in term:
        position = text.find(char, position) + 1
        if not position:
            return False
    return True

def matches(line):
    text = (line.split(args.get('delimiter', '\t'))[field] if field >= 0 else line).lower()
    for term in args['filter'].lower().split():
        if term.startswith('!'):
            if term[1:] in text:
                return False
        elif not (term[1:] in text if term.startswith("'") else fuzzy(term, text)):
            return False
    return True

kept = [line for line in sys.stdin.read().splitlines() if matches(line)]
print('\n'.join(kept))
sys.exit(0 if kept else 1)
"""

GITGUTTER_STUB = r"""function! gitgutter#all(force) abort
  call add(g:config_test_gitgutter, ['all', g:gitgutter_diff_base, g:gitgutter_async])
  call s:diff(bufnr(''))
endfunction

function! gitgutter#process_buffer(bufnr, force) abort
  call add(g:config_test_gitgutter, ['buffer', g:gitgutter_diff_base, g:gitgutter_async])
  call s:diff(a:bufnr)
endfunction

function! s:diff(bufnr) abort
  let l:file = fnamemodify(bufname(a:bufnr), ':p')
  let l:hunks = []
  for l:line in systemlist('git -C ' . shellescape(fnamemodify(l:file, ':h'))
        \ . ' diff -U0 ' . g:gitgutter_diff_base . ' -- ' . shellescape(l:file))
    let l:m = matchlist(l:line, '^@@ -\(\d\+\),\=\(\d*\) +\(\d\+\),\=\(\d*\) @@')
    if !empty(l:m)
      call add(l:hunks, [str2nr(l:m[1]), l:m[2] ==# '' ? 1 : str2nr(l:m[2]),
            \ str2nr(l:m[3]), l:m[4] ==# '' ? 1 : str2nr(l:m[4])])
    endif
  endfor
  call setbufvar(a:bufnr, 'gitgutter', {'hunks': l:hunks})
endfunction
"""

GITGUTTER_HUNK_STUB = """function! gitgutter#hunk#hunks(bufnr) abort
  return get(getbufvar(a:bufnr, 'gitgutter', {}), 'hunks', [])
endfunction

function! gitgutter#hunk#preview() abort
  call add(g:config_test_gitgutter, ['preview', line('.')])
endfunction
"""


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def main():
    vim = shutil.which(os.environ.get("VIM_CONFIG_VIM", "vim"))
    if not vim:
        print("SKIP configuration tests: classic Vim is not installed.")
        return 77
    repo = Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory(prefix="vim-config-") as directory:
        root = Path(directory)
        # A symlinked entry point must work outside the checkout, with spaces
        # and commas in its target path and with the old per-file links present.
        checkout = root / "checkout with spaces,commas"
        checkout.mkdir()
        shutil.copy2(repo / "vimrc", checkout / "vimrc")
        shutil.copytree(repo / "vim", checkout / "vim")
        home = root / "home"
        runtime = home / ".vim"
        (runtime / "autoload").mkdir(parents=True)
        (home / ".vimrc").symlink_to(checkout / "vimrc")
        write(runtime / "autoload/plug.vim", PLUG_STUB)
        write(runtime / "autoload/gutentags.vim", """function! gutentags#statusline(...) abort
  return ''
endfunction
""")
        write(runtime / "autoload/fzf.vim", """function! fzf#run(options) abort
  let g:config_test_fzf = a:options
  let g:config_test_tabs = a:options.source
endfunction
""")
        # GitGutter's hunks from a real git diff against g:gitgutter_diff_base,
        # with each call recorded.
        write(runtime / "autoload/gitgutter.vim", GITGUTTER_STUB)
        write(runtime / "autoload/gitgutter/hunk.vim", GITGUTTER_HUNK_STUB)
        write(runtime / "colors/gruvbox.vim", """call assert_equal(1, g:gruvbox_italic)
let g:colors_name = 'gruvbox'
""")
        # Simulate vim-ruby resetting tags before the personal override.
        write(runtime / "ftplugin/ruby.vim", """if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1
setlocal tags=./tags
let b:undo_ftplugin = 'setlocal tags<'
""")
        # The Ruby settings moved into vimrc; an old link to the removed
        # after/ftplugin/ruby.vim must not break startup.
        for name in ["autoload/rubytag.vim", "autoload/gitmr.vim",
                     "after/ftplugin/ruby.vim"]:
            target = runtime / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(checkout / "vim" / name)
        project = root / "project"
        project.mkdir()
        glow = root / "bin/glow"
        write(glow, GLOW_STUB)
        glow.chmod(0o755)
        glow_args = root / "glow-args.json"
        tmux = root / "bin/tmux"
        write(tmux, TMUX_STUB)
        tmux.chmod(0o755)
        fzf = root / "bin/fzf"
        write(fzf, FZF_STUB)
        fzf.chmod(0o755)
        write(project / ".vim.custom", """let g:config_test_project_loads = get(g:, 'config_test_project_loads', 0) + 1
call assert_equal(2, exists(':GitReview'))
call assert_equal(1, exists('*GitReview'))
call assert_equal(2, exists(':Glow'))
set scrolloff=7
""")
        env = {**os.environ, "HOME": str(home), "VIM_CONFIG_TEST_ROOT": str(root),
               "VIM_CONFIG_TEST_RUNTIME": str(checkout / "vim"),
               "VIM_CONFIG_TEST_GLOW_ARGS": str(glow_args),
               "VIM_CONFIG_TEST_TMUX_LOG": str(root / "tmux.log"),
               "PATH": str(glow.parent) + os.pathsep + os.environ.get("PATH", "")}
        result = subprocess.run(
            [vim, "-N", "-u", str(home / ".vimrc"), "-i", "NONE", "-n", "-es",
             "-V1" + str(root / "vim.log"), "-S", str(repo / "vim/tests/config.vim")],
            cwd=project, env=env, text=True, capture_output=True, timeout=30,
            # An unexpected prompt must fail at once instead of waiting.
            stdin=subprocess.DEVNULL,
        )
        if result.returncode:
            print(result.stdout + result.stderr)
            print((root / "vim.log").read_text())
            return 1
        if not glow_args.exists():
            print("SKIP Glow preview tests: Vim was built without +terminal.")
    print("Vim configuration passed: symlink startup, reloads, lazy commands, "
          "agent tmux prompts, filetype detection, local settings/mappings, "
          "undo and syntax reloads.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
