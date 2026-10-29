" The YAML indent plugin sets indentkeys after ftplugin/ has run.
if exists('b:dotfiles_yaml_indent')
  finish
endif
let b:dotfiles_yaml_indent = 1

setlocal indentkeys-=<:>
let b:undo_indent = get(b:, 'undo_indent', '')
      \ . (empty(get(b:, 'undo_indent', '')) ? '' : ' | ')
      \ . 'setlocal indentkeys< | unlet! b:dotfiles_yaml_indent'
