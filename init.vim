let os = substitute(system('uname'), "\n", "", "")

call plug#begin('~/.nvim/plugged')

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction

Plug 'preservim/nerdtree'
Plug 'morhetz/gruvbox'
Plug 'chusiang/vim-sdcv' " How to install dict see https://askubuntu.com/questions/191125/is-there-an-offline-command-line-dictionary
Plug 'kassio/neoterm'
Plug 'janko-m/vim-test'
Plug 'benekastah/neomake'
Plug 'Shougo/deoplete.nvim', { 'do': function('DoRemote') }
Plug 'Shougo/neco-syntax'
Plug 'tbodt/deoplete-tabnine', { 'do': './install.sh' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'itchyny/lightline.vim'
Plug 'shinchu/lightline-gruvbox.vim'
Plug 'tpope/vim-endwise'
Plug 'junegunn/gv.vim'
Plug 'tomtom/tcomment_vim'
Plug 'thinca/vim-localrc'
Plug 'jgdavey/vim-blockle'
Plug 'othree/eregex.vim'
Plug 'othree/html5.vim'
Plug 'xolox/vim-misc'
Plug 'xolox/vim-notes'
Plug 'Shougo/neco-syntax'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
Plug 'mustache/vim-mustache-handlebars'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'editorconfig/editorconfig-vim'
Plug 'rhysd/vim-grammarous'
Plug 'cespare/vim-toml'
Plug 'bfredl/nvim-miniyank'
Plug 'int3/vim-extradite'
Plug 'dzeban/vim-log-syntax'
Plug 'stephpy/vim-yaml'
Plug 'vim-scripts/dbext.vim'

" Debugger
Plug 'mfussenegger/nvim-dap'
Plug 'leoluz/nvim-dap-go'
Plug 'rcarriga/nvim-dap-ui'

" Other languages
Plug 'rust-lang/rust.vim', { 'for': 'rust' }

" After lsp with neovim 0.5.0
" Collection of common configurations for the Nvim LSP client
Plug 'neovim/nvim-lspconfig'

" Extensions to built-in LSP, for example, providing type inlay hints
Plug 'nvim-lua/lsp_extensions.nvim'

" Autocompletion framework for built-in LSP
Plug 'nvim-lua/completion-nvim'

" Highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

call plug#end()

" Import custom config for lsp
lua require("lsp_config")

" Setup debugger
lua require("dap-go").setup()

" set Python
let g:python3_host_prog  = expand('~/.asdf/shims/python')
let g:python_host_prog  = expand('~/.asdf/shims/python2')


if $TERM =~ '256'
  set termguicolors " true colors
  set t_Co=256
endif
set exrc " loads project spedific .nvimrc

"-----------------------
"""""""""""""""""""""""""
" KEYBINDINGS
"""""""""""""""""""""""""
let mapleader=","
inoremap jj <ESC>
map <C-n> :NERDTreeToggle<CR>
map <Leader>r "hy:%S/<C-r>h//gc<left><left><left>
map <Leader>f *
map <Leader>w :w<CR>
map <Leader>qa :wqa<CR>
map <Leader>[ :bprevious<CR>
map <Leader>] :bnext<CR>
" Custom yank/p to non-default buffer
" Not working with gnome's xclipboard
map <Leader>y "ky
map <Leader>p "kp
map <Leader>D "_dd<CR>
map <Leader>d "_d<CR>
map <Leader>t :Ttoggle<CR>
map // :TComment<CR>
map <Leader>r8 :vertical resize 80<CR>
map <Leader>r12 :vertical resize 130<CR>
map <F5> :so $MYVIMRC<CR>
nnoremap <leader>. :Tags <CR>
nnoremap <Leader>fu :BTags<Cr>
nnoremap <C-e> :Buffers<CR>
nnoremap <buffer><silent> <C-]> <cmd>lua vim.lsp.buf.definition()<CR>

" run set tests
nmap <silent> <leader>R :TestNearest<CR>
nmap <silent> <leader>T :TestFile<CR>
nmap <silent> <leader>A :TestSuite<CR>
nmap <silent> <leader>L :TestLast<CR>
nmap <silent> <leader>G :TestVisit<CR>

" Explain current word from dictionary
nmap <silent> <leader>d :call SearchWord()<CR>

" Fzf
nnoremap <c-p> :Files<CR>
nnoremap <silent> <expr> <c-p> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":FZF\<cr>"

" Useful maps
" closes the all terminal buffers
nnoremap <Leader>tc :call neoterm#close_all()<cr>
" clear terminal
nnoremap <Leader>tl :call neoterm#clear()<cr>

" clear highlight
map <Leader><Leader>h :set hlsearch!<CR>

" format json
map <Leader>Z :%!jq .<CR>

" regenerate CTAGS - https://github.com/universal-ctags/ctags
map <Leader>ct :silent !ctags -R --exclude="*min.js"<CR>

" Devdocs docs
command! -nargs=? DevDocs :call system('type -p open >/dev/null 2>&1 && open http://devdocs.io/#q=<args> || xdg-open http://devdocs.io/#q=<args>')
" au FileType python,ruby,rspec,javascript,html,php,eruby,coffee,haml nmap <buffer> K :exec "DevDocs " . fnameescape(expand('<cword>'))<CR>

" Grammarous
let g:grammarous#default_comments_only_filetypes = {
            \ '*' : 1, 'help' : 0, 'markdown' : 0,
            \ }

" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path
map <Leader>e :e <C-R>=escape(expand("%:p:h"),' ') . '/'<CR>
map <Leader>s :split <C-R>=escape(expand("%:p:h"), ' ') . '/'<CR>
map <Leader>v :vnew <C-R>=escape(expand("%:p:h"), ' ') . '/'<CR>

" Rust related
let g:rustfmt_autosave = 1

" Closing after autocomplete
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

" Neocomplete Settings
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#disable_auto_complete=1
inoremap <expr><Tab> pumvisible() ? "\<C-Space>" : neocomplete#start_manual_complete()

" Toggle terminal on/off (neovim)
nnoremap <c-y> :call TermToggle(12)<CR>
inoremap <c-y> <Esc>:call TermToggle(12)<CR>
tnoremap <c-y> <C-\><C-n>:call TermToggle(12)<CR>

" Terminal go back to normal mode
tnoremap <Esc> <C-\><C-n>
tnoremap :q! <C-\><C-n>:q!<CR>

" EasyMotion
nmap s <Plug>(easymotion-s2)
nmap t <Plug>(easymotion-t2)
map <Leader>l <Plug>(easymotion-lineforward)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>h <Plug>(easymotion-linebackward)

" Easy align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ea <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ea <Plug>(EasyAlign)

command! Q q " Bind :Q to :q
command! Qall qall
command! W w
" FZF
nnoremap <C-f> :FZF<cr>
let $FZF_DEFAULT_COMMAND = 'ag -g ""'

nmap <F7> :setlocal spell! spell?<CR>
" Toggle relative numbers
map <Leader>n :call NumberToggle()<CR>
" Toggle dark/ligh colortheme
map <Leader>c :call ColorToggle()<CR>
" Reload buffer after git pull, for example
map <Leader><Leader>g :call Refresh()<CR>

" Open Neomake warning/error split
nnoremap <Leader><Leader>l :lopen<CR>tocmd! BufWritePost * Neomake

" Clippy
nnoremap <leader><leader>c :call Clippy()<CR>

" Removing annoying mappings
nnoremap - <NOP>
xnoremap u <nop>

" miniyank
map p <Plug>(miniyank-startput)
map P <Plug>(miniyank-startPut)

map <leader><leader>n <Plug>(miniyank-cycle)
map <leader><leader>N <Plug>(miniyank-cycleback)

" Remove trailing space with F5
nnoremap <silent> <F5> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

" Open diagnostics loclist
nnoremap <space>l :call ToggleDiagnostics()<CR>

" Open implementation in quickfix
nnoremap <space>i :call ToggleImplementations()<CR>

" Open references in quickfix
nnoremap <space>r :call ToggleReferences()<CR>

" Show TODOs
nnoremap <space>o :call TODO()<CR>

" Debugger maps
nnoremap <silent> <leader><leader>D :lua require("dapui").open()<CR>
nnoremap <silent> <leader><leader>C :lua require("dapui").close()<CR>
nnoremap <silent> <leader><leader>T :lua require("dapui").toggle()<CR>
nnoremap <silent> <F6> :lua require'dap'.continue()<CR>
nnoremap <silent> <F8> :lua require'dap'.step_over()<CR>
nnoremap <silent> <F9> :lua require'dap'.step_into()<CR>
nnoremap <silent> <F12> :lua require'dap'.step_out()<CR>
nnoremap <silent> <leader><leader>b :lua require'dap'.toggle_breakpoint()<CR>
nnoremap <silent> <leader><leader>r :lua require'dap'.repl.open()<CR>
nnoremap <silent> <leader><leader>l :lua require'dap'.run_last()<CR>
nnoremap <silent> <F2> :lua require('dap-go').debug_test()<CR>



"""""""""""""""""""""""""
" Basic features
"""""""""""""""""""""""""

" Misc
set secure
set lazyredraw
set splitbelow
set splitright
set diffopt+=vertical
set shell=/bin/bash
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
set clipboard=unnamed
set clipboard+=unnamedplus
filetype plugin indent on " Do filetype detection and load custom file plugins and indent files
set laststatus=2          " When you go into insert mode,
                          " the status line color changes.
                          " When you leave insert mode,
                          " the status line color changes back.

" Display options
syntax on
set pastetoggle=<F12>
set nocursorline
set number
set list!                       " Display unprintable characters
set listchars=tab:▸\ ,trail:•,extends:»,precedes:«
autocmd filetype html,xml,go set listchars=tab:\│\ ,trail:-,extends:>,precedes:<,nbsp:+
colorscheme gruvbox
let g:gruvbox_contrast_dark = "medium" " soft, medium, hard
let g:gruvbox_contrast_light = "medium"
set background=dark
set t_ut= " fixes transparent BG on tmux

" Always edit file, even when swap file is found
set shortmess+=A
set hidden                         " Don't abandon buffers moved to the background
set wildmenu                       " Enhanced completion hints in command line
set backspace=eol,start,indent     " Allow backspacing over indent, eol, & start
set complete=.,w,b,u,U,t,i,d       " Do lots of scanning on tab completion
set completeopt-=preview           " Do not show preview window, just the menu
set directory=~/.config/nvim/swap  " Directory to use for the swap file
set diffopt=filler,iwhite          " In diff mode, ignore whitespace changes and align unchanged lines
set nowrap
set visualbell
set mouse=a

" Relative line numbers
set norelativenumber
autocmd InsertLeave * :call NumberToggle()
autocmd InsertEnter * :call NumberToggle()

" Nerdtree
autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Indentation and tabbing
set autoindent smartindent
set smarttab                    " Make <tab> and <backspace> smarter
set tabstop=2
set expandtab
set shiftround
set shiftwidth=2
set incsearch
" viminfo: remember certain things when we exit
" (http://vimdoc.sourceforge.net/htmldoc/usr_21.html)
"   %    : saves and restores the buffer list
"   '100 : marks will be remembered for up to 30 previously edited files
"   /100 : save 100 lines from search history
"   h    : disable hlsearch on start
"   "500 : save up to 500 lines for each register
"   :100 : up to 100 lines of command-line history will be remembered
"   n... : where to save the viminfo files
set viminfo=%100,'100,/100,h,\"500,:100,n~/.config/nvim/viminfo

" Undo
set undolevels=1000                     " How many undos
set undoreload=10000                    " number of lines to save for undo
if has("persistent_undo")
  set undodir=~/.config/nvim/undo       " Allow undoes to persist even after a file is closed
  set undofile
endif

" Diagnostics
" Set updatetime for CursorHold
" 400ms of no cursor movement to trigger CursorHold
set updatetime=400
" Show diagnostic popup on cursor hold
autocmd CursorHold *.* lua vim.diagnostic.open_float({ cursor = "line" })

" Search settings
set ignorecase
set smartcase
set hlsearch
set incsearch
set showmatch

" to_html settings
let html_number_lines = 1
let html_ignore_folding = 1
let html_use_css = 1
"let html_no_pre = 0
let use_xhtml = 1
let xml_use_xhtml = 1

" Show a vertical line/guard at column 80
let &colorcolumn=join(range(81,999),",")
highlight ColorColumn ctermbg=235 guibg=#2c2d27
let &colorcolumn="80,".join(range(131,999),",")

" terminal colors
let g:terminal_color_0  = '#2e3436'
let g:terminal_color_1  = '#cc0000'
let g:terminal_color_2  = '#4e9a06'
let g:terminal_color_3  = '#c4a000'
let g:terminal_color_4  = '#3465a4'
let g:terminal_color_5  = '#75507b'
let g:terminal_color_6  = '#0b939b'
let g:terminal_color_7  = '#d3d7cf'
let g:terminal_color_8  = '#555753'
let g:terminal_color_9  = '#ef2929'
let g:terminal_color_10 = '#8ae234'
let g:terminal_color_11 = '#fce94f'
let g:terminal_color_12 = '#729fcf'
let g:terminal_color_13 = '#ad7fa8'
let g:terminal_color_14 = '#00f5e9'
let g:terminal_color_15 = '#eeeeec'

"""""""""""""""""""""""""
" Plugin's
"""""""""""""""""""""""""

" Ack.vim
" Note: by using it like Ack! it avoids auto jump to first file
cnoreabbrev ag Ack! -Q
cnoreabbrev aG Ack! -Q
cnoreabbrev Ag Ack! -Q
cnoreabbrev AG Ack! -Q
cnoreabbrev F Ack! -Q
cnoreabbrev f Ack! -Q
if executable('ag')
  let g:ackprg = 'ag --vimgrep --smart-case'
endif

" Use deoplete.
let g:deoplete#enable_at_startup = 1
call deoplete#custom#source('_', 'max_candidates', 3)
call deoplete#custom#source('buffer', 'rank', 501)
call deoplete#custom#source('buffer', 'max_candidates', 2)

" use tab
imap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ deoplete#mappings#manual_complete()
function! s:check_back_space() abort "{{{
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}

" For clang with
let g:clang_complete_auto = 0
let g:clang_auto_select = 0
let g:clang_omnicppcomplete_compliance = 0
let g:clang_make_default_keymappings = 0
let g:clang_library_path = '/usr/local/opt/llvm/lib'

" Ultisnip
let g:UltiSnipsExpandTrigger="<C-j>"
let g:UltiSnipsSnippetsDir="~/.config/nvim/UltiSnips"

" Notes
let g:notes_directories = ['~/notes']
let g:notes_tab_indents = 0
let g:notes_word_boundaries = 1

" Lightline
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified', 'gitbranch'] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head',
      \   'filename': 'LightlineFilename'
      \ },
      \ }

" Not show INSERT mode when, well, in INSERT mode
set noshowmode

" Vim test
let test#strategy = "neoterm"

" Neomake
" let g:neomake_verbose = 3
let g:neomake_logfile = '/tmp/neomake.log'
" let g:neomake_javascript_enabled_makers = ['eslint']
" let g:neomake_serialize = 1
" let g:neomake_serialize_abort_on_error = 1

" Neoterm
let g:neoterm_clear_cmd = "clear; printf '=%.0s' {1..80}; clear"
let g:neoterm_run_tests_bg = 1
let g:neoterm_raise_when_tests_fail = 1
let g:neoterm_default_mod = 'botright'
let g:neoterm_size = 10
let g:neoterm_autoscroll = 1
"
" JS libs
let g:used_javascript_libs = 'jquery,handlebars,underscore,backbone'

" ignored files
set wildignore+=tags
set wildignore+=*/tmp/*
set wildignore+=*/spec/vcr/*
set wildignore+=*/public/*
set wildignore+=*/coverage/*
set wildignore+=*.png,*.jpg,*.otf,*.woff,*.jpeg,*.orig

" Markdown
let g:vim_markdown_folding_disabled=1

" EasyMotion
" Use uppercase target labels and type as a lower case
let g:EasyMotion_use_upper = 1
" type `l` and match `l`&`L`
let g:EasyMotion_smartcase = 1
" Smartsign (type `3` and match `3`&`#`)
let g:EasyMotion_use_smartsign_us = 1

" omnifuncs
set omnifunc=syntaxcomplete#Complete
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete

" Markdown
autocmd BufRead,BufNewFile *.md setlocal textwidth=80

" Turn on spellcheck
autocmd Filetype gitcommit,markdown,note setlocal spell textwidth=72
autocmd Filetype gitcommit,markdown,note setlocal complete+=kspell

" Rusts' ctags (check README for more info)
autocmd BufRead *.rs :setlocal tags=./.rstags;/,$RUST_SRC_PATH/.rstags
autocmd BufWritePost *.rs :silent! exec "!rusty-tags vi --quiet --start-dir=" . expand('%:p:h') . "&" | redraw!

" Go
autocmd BufWritePre *.go lua vim.lsp.buf.format({ async = false })
autocmd BufWritePre *.go lua goimports(1000)
autocmd FileType go set noexpandtab
autocmd FileType go set nolist
" to update or close qickfix|loclist on save
autocmd BufWritePost *.go call UpdateLoclist()

" Rust

" Use LSP omni-completion in Rust files
autocmd Filetype rust setlocal omnifunc=v:lua.vim.lsp.omnifunc

" Autoclose quickfix or loclist on closing editor
autocmd BufWinEnter quickfix nnoremap <silent> <buffer>
            \   q :cclose<cr>:lclose<cr>
autocmd BufEnter * if (winnr('$') == 1 && &buftype ==# 'quickfix' ) |
            \   bd|
            \   q | endif


"""""""""""""""""""""""""
" Functions
"""""""""""""""""""""""""

" Retrieve all TODOs
function! TODO()
    let wins = filter(getwininfo(), 'v:val.quickfix')
    " If closed, do it
    if wins == []
      execute ":Ack! -Q 'TODO' ."
      return
    endif
    cclose
endfunction

" Toggle references
function! ToggleReferences()
    let wins = filter(getwininfo(), 'v:val.quickfix')
    " If closed, do it
    if wins == []
      lua vim.lsp.buf.references()
      return
    endif
    cclose
endfunction


" Toggle implementations
function! ToggleImplementations()
    let wins = filter(getwininfo(), 'v:val.quickfix')
    " If closed, do it
    if wins == []
      lua vim.lsp.buf.implementation()
      return
    endif
    cclose
endfunction

" Toggles diagnostics in loclist
function! ToggleDiagnostics()
    let wins = filter(getwininfo(), 'v:val.quickfix || v:val.loclist')
    " If closed, do it
    if wins == []
      lua vim.diagnostic.setloclist()
      return
    endif
    lclose
endfunction

" Updates loclist
function! UpdateLoclist()
    " Check loclist or quickfix
    let wins = filter(getwininfo(), 'v:val.quickfix || v:val.loclist')
    " If non open, don't do anything
    if wins == []
      return
    endif
    " restart the loclist (add quickfix if needed later on)
    lua vim.diagnostic.setloclist()
    " if after restart it's empty, quit the loclist (lclose)
    if len(getloclist(0)) == 0
      lclose
      return
    endif
    " go back to loclist after save
    let winnr = wins[0]['winnr']
    exe winnr."wincmd w"
endfunction

" Exec clippy for rust project
function! Clippy()
  let extension = expand('%:e')
  if extension == 'rs'
    let file_dir = expand('%:p')
    let splitted = split(file_dir, '/')
    let curr_file_dir = join(['/'] + splitted[:-2], '/')
    let cargo_dir = join([curr_file_dir, 'Cargo.toml'], '/')
    let iters = 0
    while !filereadable(cargo_dir) && iters <= 10
      let splitted = split(curr_file_dir, '/')
      let curr_file_dir = join(['/'] + splitted[:-2], '/')
      let cargo_dir = join([curr_file_dir, 'Cargo.toml'], '/')
      echo cargo_dir
      let iters += 1
    endwhile
    if iters == 11
      echo 'not a cargo project'
      return
    endif
    silent exe 'cd' curr_file_dir
    exe "!cargo clippy"
  else
    echo 'not a rust file'
  endif
endfunction

"This allows for change paste motion cp{motion}
nmap <silent> cp :set opfunc=ChangePaste<CR>g@
function! ChangePaste(type, ...)
    silent exe "normal! `[v`]\"_c"
    silent exe "normal! p"
endfunction

" When opening a file, always jump to the last cursor position
autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \     exe "normal g'\"" |
    \ endif |

function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
    set number
  else
    set relativenumber
  endif
endfunc

function! ColorToggle()
  if(&background == "dark")
    set background=light
  else
    set background=dark
  endif
endfunction

function! LightlineFilename()
  return &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
        \ &filetype ==# 'unite' ? unite#get_status_string() :
        \ &filetype ==# 'vimshell' ? vimshell#get_status_string() :
        \ expand('%:t') !=# '' ? expand('%:p:h:t') . '/' . expand('%:t') : '[No Name]'
endfunction

" Terminal Function
let g:term_buf = 0
let g:term_win = 0
function! TermToggle(height)
    if win_gotoid(g:term_win)
        hide
    else
        botright new
        exec "resize " . a:height
        try
            exec "buffer " . g:term_buf
        catch
            call termopen($SHELL, {"detach": 0})
            let g:term_buf = bufnr("")
            set nonumber
            set norelativenumber
            set signcolumn=no
        endtry
        startinsert!
        let g:term_win = win_getid()
    endif
endfunction

function! NERDTreeHighlightFile(extension, fg, bg, guifg)
   exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guifg='. a:guifg
   exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

function! s:CloseIfOnlyControlWinLeft()
    if winnr("$") != 1
        return
    endif
    if (exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName) != -1)
        \ || &buftype == 'quickfix'
        q
    endif
endfunction

function! Refresh()
  set autoread
  checkt
  set autoread
endfunction

augroup CloseIfOnlyControlWinLeft
    au!
    au BufEnter * call s:CloseIfOnlyControlWinLeft()
augroup END

call NERDTreeHighlightFile('jade', 'green', 'none', 'green')
call NERDTreeHighlightFile('ini', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF')
call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow')
call NERDTreeHighlightFile('styl', 'cyan', 'none', 'cyan')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan')
call NERDTreeHighlightFile('ex', 'cyan', 'none', 'cyan')
call NERDTreeHighlightFile('rb', 'Red', 'none', 'red')
call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500')
call NERDTreeHighlightFile('ts', 'Magenta', 'none', '#ff00ff')
call NERDTreeHighlightFile('go', 'green', 'none', 'green')
call NERDTreeHighlightFile('py', 'cyan', 'none', 'red')
call NERDTreeHighlightFile('rs', 'Magenta', 'none', '#ff00ff')

if $VIM_CRONTAB == "true"
    set nobackup
    set nowritebackup
endif

