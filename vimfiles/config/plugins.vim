" ZoomWin configuration
map <Leader>z :ZoomWin<CR>

" Without setting this, ZoomWin restores windows in a way that causes
" equalalways behavior to be triggered the next time CommandT is used.
" This is likely a bludgeon to solve some other issue, but it works
set noequalalways

" Ack
nmap <Leader>g :Ack
nmap <Leader>G :AckG

" Snippets
let g:snippetsEmu_key = "<S-Tab>"
let g:snippets_dir = '$HOME/.vim/_snippets/'
map <Leader>snip :call ReloadAllSnippets()<CR>
map <Leader>snipc :e ~/.vim/_snippets/coffee.snippets<CR>
map <Leader>snipr :e ~/.vim/_snippets/ruby.snippets<CR>
map <Leader>snipj :e ~/.vim/_snippets/javascript.snippets<CR>
map <Leader>snipa :e ~/.vim/_snippets/_.snippets<CR>

" NERDTree
let NERDChristmasTree = 1
let NERDTreeHighlightCursorline = 1
let NERDTreeShowBookmarks = 1
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\~$', '.svn$', '\.git$', '.DS_Store', '.sass-cache']

" BuffExplorer
nnoremap <C-B> :BufExplorer<cr>
let g:bufExplorerShowRelativePath=1

" CtrlP
let g:ctrlp_map = '<c-f>'
let g:ctrlp_cmd = 'CtrlP'

let g:ctrlp_custom_ignore = {
	\ 'dir':  '\.git$\|\.hg$\|\.svn$',
	\ 'file': '\.exe$\|\.so$\|\.dll$',
	\ 'link': 'some_bad_symbolic_link',
	\ }

" Syntastic
" mark syntax errors with :signs
let g:syntastic_enable_signs=1

" Sparkup
let g:sparkupExecuteMapping = '<C-S-e>'
let g:sparkupNextMapping = '<C-S-x>'

" Rails
" Leader shortcuts for Rails commands
map <Leader>m :Rmodel
map <Leader>c :Rcontroller
map <Leader>v :Rview
"map <Leader>u :Runittest
"map <Leader>f :Rfunctionaltest
"map <Leader>tm :RTmodel
"map <Leader>tc :RTcontroller
"map <Leader>tv :RTview
"map <Leader>tu :RTunittest
"map <Leader>tf :RTfunctionaltest
"map <Leader>sm :RSmodel
"map <Leader>sc :RScontroller
"map <Leader>sv :RSview
"map <Leader>su :RSunittest
"map <Leader>sf :RSfunctionaltest

map <Leader>ts :let file_to_run = "<c-r>%"<cr>
" Execute the results of concatenating the strings below. last_run_file is set
" above.
" map <Leader>tt :exe '!ruby -I"test" -I"spec"' file_to_run<cr>

" Edit routes
command! Rroutes :e config/routes.rb
command! RTroutes :tabe config/routes.rb

