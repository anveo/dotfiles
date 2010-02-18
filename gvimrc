colorscheme vibrantink

" Nicer font
set guifont=Monaco:h14

let os = substitute(system('uname'), "\n", "", "")
if os == "Linux"
  set guifont=Monaco\ 12
endif

" No icky toolbar, menu or scrollbars in the GUI
if has('gui')
  set guioptions+=a " Automatically make visual selection available in system clipboard
  set guioptions-=m
  set guioptions-=T
  set guioptions-=l
  "set guioptions-=L
  "set guioptions-=r
  set guioptions-=R
  set guioptions+=b
  set mousehide                   " Hide the mouse while typing
end

" MacVim {{{2
if has('gui_macvim')
  set fuoptions=maxvert,maxhorz " Full-screen mode uses the full screen
endif

" Enable the tab bar
" set showtabline=2 " 2=always
