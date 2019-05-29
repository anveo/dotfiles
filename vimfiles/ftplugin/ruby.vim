" bind control-l to hashrocket
" imap <C-l> <Space>=><Space>
" convert word into ruby symbol
" imap <C-k> <C-o>b:<Esc>ea
"imap <C-k> <C-o>mu<Esc>bi:<Esc>'u
" nmap <C-k> lbi:<Esc>E

function! s:InsertInterpolation()
  let before = getline('.')[col('^'):col('.')]
  let after  = getline('.')[col('.'):col('$')]
  " check that we're in double-quotes string
  if before =~# '"' && after =~# '"'
    execute "normal! a{}\<Esc>h"
  endif
endfunction
inoremap <silent><buffer> # #<Esc>:call <SID>InsertInterpolation()<Cr>a

" Surround with #
if exists("g:loaded_surround")
  let b:surround_{char2nr('#')} = "#{\r}"
endif
