colorscheme vibrantink

" Nicer font
set guifont=Monaco:h14

let os = substitute(system('uname'), "\n", "", "")
if os == "Linux"
  set guifont=Monaco\ 12
endif

" No icky toolbar, menu or scrollbars in the GUI
if has('gui')
  set guioptions-=m
  set guioptions-=T
  set guioptions-=l
  "set guioptions-=L
  "set guioptions-=r
  set guioptions-=R
  set guioptions+=b
end

" Enable the tab bar
" set showtabline=2 " 2=always
