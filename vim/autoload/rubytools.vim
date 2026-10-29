function! rubytools#api() abort
    let word = expand('<cword>')
    let cmd = "ruby -v | sed -E 's/^ruby\\s([0-9]+\\.[0-9]+).*/\\1/'"
    let ruby_version = trim(system(cmd))
    let url = 'https://rubyapi.org/' . ruby_version . '/o/s?q=' . word
    execute '!xdg-open ' . shellescape(url)
endfunction

function! rubytools#spec() abort
  " Get the current file's path
  let l:current_file_path = expand('%:p')

  " Transform the path to the corresponding spec path
  let l:spec_file_path = substitute(l:current_file_path, 'app/', 'spec/', '')
  let l:spec_file_path = substitute(l:spec_file_path, '.rb', '_spec.rb', '')

  " Create the directory for the spec file if it doesn't exist
  execute '!mkdir -p ' . fnamemodify(l:spec_file_path, ':h')

  " Open the spec file
  execute 'edit ' . l:spec_file_path
endfunction
