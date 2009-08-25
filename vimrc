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

" Columns are cooler than rows
noremap ' `
noremap ` '

"Show line number
  set nu

"Don't highlight search results and ignore case
set nohlsearch
set ignorecase

" Snippets are activated by Shift+Tab
" let g:snippetsEmu_key = "<S-Tab>"
" Tab completion options
" " (only complete to the longest unambiguous match, and show a menu)
set completeopt=longest,menu
set wildmode=list:longest,list:full
set complete=.,t

if has("folding")
 set foldenable
 set foldmethod=syntax
 set foldlevel=1
 set foldnestmax=2
 set foldtext=strpart(getline(v:foldstart),0,50).'\ ...\ '.substitute(getline(v:foldend),'^[\ #]*','','g').'\ '
endif

colorscheme vibrantink
highlight NonText guibg=#060606
highlight Folded guibg=#0A0A0A guifg=#9090D0

" Make NerdCommenter and VCSCommand play nice
let NERDMapleader = ',cc'
let NERDShutUp = 1

" For Haml
au! BufRead,BufNewFile *.haml setfiletype haml

" No Help, please
nmap <F1> <Esc>

" Press Shift+P while in visual mode to replace the selection without
" overwriting the default register
vmap P p :call setreg('"', getreg('0')) <CR>

" map <F7> to toggle NERDTree window
nmap <silent> <F7> :NERDTreeToggle<CR>

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

let g:fuzzy_ceiling = 30000
let g:fuzzy_ignore = "gems/*;*.jpg;*.png;*.gif;*.zip;*.tar.gz"
