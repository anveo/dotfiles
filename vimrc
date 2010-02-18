source ~/.vim/vimrc

" Easier non-interactive command insertion
nnoremap <Space> :

"Set mapleader
let mapleader = ","
let g:mapleader = ","

" Make it easy to update/reload .vimrc
nmap <leader>s :source ~/.vimrc<CR>
nmap <leader>vi :tabe ~/.vimrc<CR>

" Columns are cooler than rows
noremap ' `
noremap ` '
noremap g' g`
noremap g` g'

" Show line numbers
set number
set numberwidth=3

" Ignore case
set ignorecase
" Case sentisive searching if using uppercase letter
set smartcase

" Jump to end of line in insert mode
imap <C-j> <End>

" ack
set grepprg=ack
set grepformat=%f:%l:%m

nmap <Leader>g :Ack
nmap <Leader>G :AckG

" Terminal Stuff
if &term =~? '^\(xterm\|screen\|putty\|konsole\|gnome\)'
  let &t_RV="\<Esc>[>c" " Let Vim check for xterm-compatibility
  set ttyfast " Because no one should have to suffer
  set ttymouse=xterm2 " Assume xterm mouse support
endif

" Snippets are activated by Shift+Tab
let g:snippetsEmu_key = "<S-Tab>"
" Tab completion options
" " (only complete to the longest unambiguous match, and show a menu)
"set completeopt=longest,menu
"set complete=.,t

if has("folding")
 set foldenable
 set foldmethod=syntax
 set foldlevel=1
 set foldnestmax=2
 set foldtext=strpart(getline(v:foldstart),0,50).'\ ...\ '.substitute(getline(v:foldend),'^[\ #]*','','g').'\ '
endif

colorscheme koehler
highlight NonText guibg=#060606
highlight Folded guibg=#0A0A0A guifg=#9090D0

" Make NerdCommenter and VCSCommand play nice
let NERDMapleader = ',cc'
let NERDShutUp = 1

" For Haml
au! BufRead,BufNewFile *.haml setfiletype haml

" No Help, please
nmap <F1> <Esc>
map! <F1> <Esc>

" Press Shift+P while in visual mode to replace the selection without
" overwriting the default register
vmap P p :call setreg('"', getreg('0')) <CR>

" map <F7> to toggle NERDTree window
nmap <leader>d :NERDTreeToggle<CR>
nmap <silent> <F7> :NERDTreeToggle<CR>
nmap <silent> <F6> :TlistToggle<CR>

" Close buffer when tab is closed
set nohidden

" open tabs with command-<tab number>
map <D-1> :tabn 1<CR>
map <D-2> :tabn 2<CR>
map <D-3> :tabn 3<CR>
map <D-4> :tabn 4<CR>
map <D-5> :tabn 5<CR>
map <D-6> :tabn 6<CR>
map <D-7> :tabn 7<CR>
map <D-8> :tabn 8<CR>
map <D-9> :tabn 9<CR>

nmap <leader>v :vsplit<CR> <C-w><C-w>
nmap <leader>s :split<CR> <C-w><C-w>

" NERDTree
let NERDChristmasTree = 1
let NERDTreeHighlightCursorline = 1
let NERDTreeShowBookmarks = 1
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['.vim$', '\~$', '.svn$', '\.git$', '.DS_Store']

" TagList
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_Process_File_Always = 1
let Tlist_Inc_Winwidth = 0
let Tlist_Enable_Fold_Column = 0 "Disable drawing the fold column
let Tlist_Use_SingleClick = 1 "Single click tag selection
let Tlist_Use_Right_Window = 1
let Tlist_Exit_OnlyWindow = 1 "Exit if only the taglist is open
let Tlist_File_Fold_Auto_Close = 1 " Only auto expand the current file
"let Tlist_Ctags_Cmd = '/opt/local/bin/ctags'

" bind control-l to hashrocket
imap <C-l> <Space>=><Space>"
" convert word into ruby symbol
imap <C-k> <C-o>b:<Esc>Ea
nmap <C-k> lbi:<Esc>E

" Leader shortcuts for Rails commands
map <Leader>m :Rmodel
map <Leader>c :Rcontroller
map <Leader>v :Rview
map <Leader>u :Runittest
map <Leader>f :Rfunctionaltest
map <Leader>tm :RTmodel
map <Leader>tc :RTcontroller
map <Leader>tv :RTview
map <Leader>tu :RTunittest
map <Leader>tf :RTfunctionaltest
map <Leader>sm :RSmodel
map <Leader>sc :RScontroller
map <Leader>sv :RSview
map <Leader>su :RSunittest
map <Leader>sf :RSfunctionaltest

" Edit routes
command! Rroutes :e config/routes.rb
command! RTroutes :tabe config/routes.rb

" Turn on language specific omnifuncs
autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 0
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 0
autocmd FileType ruby,eruby let g:rubycomplete_include_object = 0
autocmd FileType ruby,eruby let g:rubycomplete_include_objectspace = 0

autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType c set omnifunc=ccomplete#Complete
