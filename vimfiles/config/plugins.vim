" Powerline
let g:Powerline_symbols = 'fancy'

" jellybeans colorscheme
let g:jellybeans_use_lowcolor_black = 1

" ZoomWin configuration
map <Leader>z :ZoomWin<CR>

" Without setting this, ZoomWin restores windows in a way that causes
" equalalways behavior to be triggered the next time CommandT is used.
" This is likely a bludgeon to solve some other issue, but it works
set noequalalways

" Ack
nmap <Leader>g :Ack
nmap <Leader>G :AckG
let g:ackprg = 'ag --nogroup --nocolor --column'

" Snippets
let g:snippetsEmu_key = "<S-Tab>"
let g:snippets_dir = '$HOME/.vim/_snippets/'
map <Leader>snip :call ReloadAllSnippets()<CR>
map <Leader>snipc :e ~/.vim/_snippets/coffee.snippets<CR>
map <Leader>snipr :e ~/.vim/_snippets/ruby.snippets<CR>
map <Leader>snipj :e ~/.vim/_snippets/javascript.snippets<CR>
map <Leader>snipa :e ~/.vim/_snippets/_.snippets<CR>

" CSApprox
let g:CSApprox_verbose_level = 0

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
	\ 'dir':  '\.git$\|\.hg$\|\.svn$|tmp$',
	\ 'file': '\.exe$\|\.so$\|\.dll$',
	\ 'link': 'some_bad_symbolic_link',
	\ }

" Syntastic
" mark syntax errors with :signs
let g:syntastic_enable_signs=1
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'


let g:syntastic_mode_map = { 'mode': 'active',
                           \ 'passive_filetypes': ['scss'] }

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

" YankRing
map <Leader>yy :YRShow<cr>

" TagList
nnoremap <silent> <F8> :TlistToggle<CR>
let Tlist_Exit_OnlyWindow = 1     " exit if taglist is last window open
let Tlist_Show_One_File = 1       " Only show tags for current buffer
let Tlist_Enable_Fold_Column = 0  " no fold column (only showing one file)
let Tlist_Use_Right_Window = 1
let tlist_sql_settings = 'sql;P:package;t:table'
let tlist_ant_settings = 'ant;p:Project;r:Property;t:Target'

" Tagbar
nmap <F9> :TagbarToggle<CR>
