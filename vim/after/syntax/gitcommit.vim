syntax match GitWordAdd /{+.\{-}+}/ containedin=ALL
syntax match GitWordDel /\[-.\{-}-\]/ containedin=ALL
highlight GitWordAdd ctermbg=2 guibg=#005f00 ctermfg=NONE guifg=NONE
highlight GitWordDel ctermbg=1 guibg=#5f0000 ctermfg=NONE guifg=NONE
