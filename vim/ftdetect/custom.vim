" Filetype detection only; settings belong in after/ftplugin/.
augroup dotfiles_filetypes
  autocmd!
  autocmd BufNewFile,BufRead Guardfile setfiletype ruby
  autocmd BufNewFile,BufRead .env.local,*.env.* setfiletype sh
  autocmd BufNewFile,BufRead *.go setfiletype go
augroup END
