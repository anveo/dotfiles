" Nicer font
set guifont=Monaco\ 12

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
