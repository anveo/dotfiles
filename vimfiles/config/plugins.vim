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
nmap <Leader>f :Ack!
nmap <Leader>ff :Ack!<Space>
"nmap <Leader>F :AckFromSearch!<Space>
" Highlight and Ack for the word under the cursor
nnoremap <leader>F    *<C-O>:AckFromSearch!<CR>
" Ack for the current selection
vnoremap <leader>F    "dy:Ack!<space>'<C-r>d'<CR>

if executable("ack")
  " use default config
elseif executable("ack-grep")
  let g:ackprg="ack-grep -H --nocolor --nogroup --column"
elseif executable("ag")
  let g:ackprg="ag -S --follow --nocolor --nogroup --column"
else
endif

" CSApprox
let g:CSApprox_verbose_level = 0

" NERDTree
let NERDChristmasTree = 1
let NERDTreeHighlightCursorline = 1
let NERDTreeShowBookmarks = 1
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\~$', '.svn$', '\.git$', '.DS_Store', '.sass-cache']

" NERDCommenter
let NERDSpaceDelims=1

" BuffExplorer
nnoremap <C-B> :BufExplorer<cr>
let g:bufExplorerShowRelativePath=1

" CtrlP
let g:ctrlp_map = '<c-f>'
let g:ctrlp_cmd = 'CtrlP'

let g:ctrlp_use_caching = 0
if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor

    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
else
  let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'find %s -type f']
  let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<space>', '<cr>', '<2-LeftMouse>'],
    \ }
endif

let g:ctrlp_custom_ignore = {
	\ 'dir':  '\.git$\|\.hg$\|\.svn$|tmp$\|node_modules\|.kitchen',
	\ 'file': '\.exe$\|\.so$\|\.dll$',
	\ 'link': 'some_bad_symbolic_link',
	\ }

" Syntastic
" mark syntax errors with :signs
let g:syntastic_enable_signs=1
"let g:syntastic_error_symbol='✗'
"let g:syntastic_warning_symbol='⚠'


let g:syntastic_mode_map = { 'mode': 'active',
                           \ 'passive_filetypes': ['scss', 'php'] }

" Sparkup
"let g:sparkupExecuteMapping = '<C-S-e>'
"let g:sparkupNextMapping = '<C-S-x>'
" Emmit
let g:user_emmet_leader_key='<C-e>'

" Rails
" Leader shortcuts for Rails commands
map <Leader>m :Emodel<Space>
map <Leader>c :Econtroller<Space>
map <Leader>v :Eview<Space>
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

" Processing
let g:use_processing_java=1

" vim-easy-align
" Start interactive EasyAlign in visual mode
vmap <Enter> <Plug>(EasyAlign)
" Start interactive EasyAlign with a Vim movement
nmap <leader>a <Plug>(EasyAlign)

" vim-tmux-navigator
"let g:tmux_navigator_no_mappings = 1
"
"nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
"nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
"nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
"nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
"nnoremap <silent> <C-\> :TmuxNavigatePrevious<cr>

" vim-mustache-handlebars
let g:mustache_abbreviations = 1

" easymotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings"
map <Leader>e <Plug>(easymotion-prefix)

nmap <Leader>ew <Plug>(easymotion-w)

" Bi-directional find motion
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
nmap s <Plug>(easymotion-s)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-s2)

" Turn on case sensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" These `n` & `N` mappings are options. You do not have to map `n` & `N` to EasyMotion.
" Without these mappings, `n` & `N` works fine. (These mappings just provide
" different highlight method and have some other features )
"map  n <Plug>(easymotion-next)
"map  N <Plug>(easymotion-prev)

" Dash
nmap <silent> <leader>gg <Plug>DashSearch

" vim expand region
vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

" powerline
let g:airline_powerline_fonts = 1

" Deoplete
let g:deoplete#enable_at_startup = 1
" use tab for completion
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

" Run Neomake when I save any buffer
" augroup localneomake
  " autocmd! BufWritePost * Neomake
" augroup END
" Don't tell me to use smartquotes in markdown ok?
let g:neomake_markdown_enabled_makers = []

let g:neomake_elixir_enabled_makers = ['mix', 'credo']
" Run Neomake when I save any buffer
augroup neomake
  autocmd! BufWritePost * Neomake
augroup END
" Don't tell me to use smartquotes in markdown ok?
let g:neomake_markdown_enabled_makers = []

" Configure a nice credo setup, courtesy https://github.com/neomake/neomake/pull/300
let g:neomake_elixir_enabled_makers = ['mycredo']
function! NeomakeCredoErrorType(entry)
  if a:entry.type ==# 'F'      " Refactoring opportunities
    let l:type = 'W'
  elseif a:entry.type ==# 'D'  " Software design suggestions
    let l:type = 'I'
  elseif a:entry.type ==# 'W'  " Warnings
    let l:type = 'W'
  elseif a:entry.type ==# 'R'  " Readability suggestions
    let l:type = 'I'
  elseif a:entry.type ==# 'C'  " Convention violation
    let l:type = 'W'
  else
    let l:type = 'M'           " Everything else is a message
  endif
  let a:entry.type = l:type
endfunction

let g:neomake_elixir_mycredo_maker = {
      \ 'exe': 'mix',
      \ 'args': ['credo', 'list', '%:p', '--format=oneline'],
      \ 'errorformat': '[%t] %. %f:%l:%c %m,[%t] %. %f:%l %m',
      \ 'postprocess': function('NeomakeCredoErrorType')
      \ }

" Snippets
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <c-k> <Plug>(neosnippet_expand_or_jump)
smap <c-k> <Plug>(neosnippet_expand_or_jump)
xmap <c-k> <Plug>(neosnippet_expand_target)
" vmap <c-k> <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <expr><TAB>
\ pumvisible() ? "\<C-n>" :
\ neosnippet#expandable_or_jumpable() ?
\    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" disable all snippets
let g:neosnippet#disable_runtime_snippets = {
\   '_' : 1,
\ }

" Enable snipMate compatibility feature.
" let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='$HOME/.vim/_snippets'

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif
