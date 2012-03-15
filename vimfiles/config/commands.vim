" Quicker filetype setting:
"   :F html
" instead of
"   :set ft=html
" Can tab-complete filetype.
command! -nargs=1 -complete=filetype F set filetype=<args>

" Even quicker setting often-used filetypes.
command! FC set filetype=coffee
command! FH set filetype=haml
command! FR set filetype=ruby
command! FV set filetype=vim

" Strip trailing whitespace (including that in blank lines).
" http://vim.wikia.com/wiki/Remove_unwanted_spaces
command! Strip let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl

" Convert Ruby 1.8 hash rockets to 1.9 JSON style hashes.
" Based on https://github.com/hashrocket/dotmatrix/commit/6c77175adc19e94594e8f2d6ec29371f5539ceeb
command! -bar -range=% NotRocket execute '<line1>,<line2>s/:\(\w\+\)\s*=>/\1:/e' . (&gdefault ? '' : 'g')

" Save a file as root.
cabbrev w!! w !sudo tee % > /dev/null<CR>:e!<CR><CR>
"cmap w!! w !sudo tee % >/dev/null
