source ~/.vim/vimrc      "linux

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set sts=2
set sw=2

"Set mapleader
let mapleader = ","
let g:mapleader = ","

" Make it easy to update/reload .vimrc
nmap <leader>s :source ~/.vimrc<CR>
nmap <leader>vi :tabe ~/.vimrc<CR>

" Columns are cooler than rows
noremap ' `
noremap ` '

"Show line number
set number
set numberwidth=3

"Don't highlight search results and ignore case
set nohlsearch
set ignorecase

" ack
set grepprg=ack
set grepformat=%f:%l:%m

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
nmap <silent> <F7> :NERDTreeToggle<CR>
nmap <silent> <F6> :TlistToggle<CR>

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
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
autocmd FileType ruby,eruby let g:rubycomplete_include_object = 0
autocmd FileType ruby,eruby let g:rubycomplete_include_objectspace = 0

autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType c set omnifunc=ccomplete#Complete
