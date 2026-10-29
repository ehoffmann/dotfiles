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
  let g:config_test_tabs = a:options.source
endfunction
""")
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
        for name in ["autoload/rubytag.vim", "autoload/gitmr.vim",
                     "after/ftplugin/ruby.vim"]:
            target = runtime / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(checkout / "vim" / name)
        project = root / "project"
        project.mkdir()
        write(project / ".vim.custom", """let g:config_test_project_loads = get(g:, 'config_test_project_loads', 0) + 1
call assert_equal(2, exists(':GitReview'))
call assert_equal(1, exists('*GitReview'))
call assert_equal(2, exists(':Glow'))
set scrolloff=7
""")
        env = {**os.environ, "HOME": str(home), "VIM_CONFIG_TEST_ROOT": str(root),
               "VIM_CONFIG_TEST_RUNTIME": str(checkout / "vim")}
        result = subprocess.run(
            [vim, "-N", "-u", str(home / ".vimrc"), "-i", "NONE", "-n", "-es",
             "-V1" + str(root / "vim.log"), "-S", str(repo / "vim/tests/config.vim")],
            cwd=project, env=env, text=True, capture_output=True, timeout=30,
        )
        if result.returncode:
            print(result.stdout + result.stderr)
            print((root / "vim.log").read_text())
            return 1
    print("Vim configuration passed: symlink startup, reloads, lazy commands, "
          "filetype detection, local settings/mappings, undo and syntax reloads.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
