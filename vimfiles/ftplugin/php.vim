" Map <CTRL>-H to search phpm for the function name currently under the cursor (insert mode only)
inoremap <buffer> <C-H> <ESC>:!phpm <C-R>=expand("<cword>")<CR><CR>

" Map ; to "add ; to the end of the line, when missing"
noremap <buffer> ; :s/\([^;]\)$/\1;/<cr>"
