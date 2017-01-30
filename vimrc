" ---------------------------------- "
" General settings
" ---------------------------------- "

set nocompatible " not vi compatible
set backspace=2 " make backspace work like most other apps
set encoding=utf8
syntax on
set number " show line numbers
set noerrorbells
set visualbell

" Create a vertical split using :vsp and horizontal with :sp
set splitbelow " make the new window appear below the current window
set splitright " make the new window appear on the right
nnoremap <C-J> <C-W><C-J> " Ctrl-j move to the split below
nnoremap <C-K> <C-W><C-K> " Ctrl-k move to the split above
nnoremap <C-L> <C-W><C-L> " Ctrl-l move to the split to the right
nnoremap <C-H> <C-W><C-H> " Ctrl-h move to the split to the left

" Enable folding
nnoremap <space> za " Enable folding with the spacebar
set foldmethod=indent
set foldnestmax=2
set foldlevel=2 " Automatically fold at level n

" Python PEP8
" au BufNewFile,BufRead *.py set tabstop=4
" au BufNewFile,BufRead *.py set softtabstop=4
" au BufNewFile,BufRead *.py set shiftwidth=4
" au BufNewFile,BufRead *.py set textwidth=79
" au BufNewFile,BufRead *.py set expandtab
" au BufNewFile,BufRead *.py set autoindent
" au BufNewFile,BufRead *.py set fileformat=unix
" autocmd FileType python set sw=4
" autocmd FileType python set ts=4
" autocmd FileType python set sts=4

" ---------------------------------- "
" Plugins
" ---------------------------------- "

" call plug#begin('~/.config/nvim/plugged')
call plug#begin('~/.vim/plugged')

Plug 'chriskempson/base16-vim' " Colorschemes
Plug 'scrooloose/syntastic' " Syntax check
Plug 'scrooloose/nerdtree' " File browser
Plug 'jistr/vim-nerdtree-tabs' " Improves NERDTree
Plug 'kien/ctrlp.vim' " Search for file
Plug 'tpope/vim-fugitive' " Git commands
Plug 'vim-airline/vim-airline' " fancy statusline
Plug 'vim-airline/vim-airline-themes' " themes for vim-airline
Plug 'severin-lemaignan/vim-minimap' " minimap

" Plug 'nvie/vim-flake8', { 'for': 'python' } " Python Flake 8 check
Plug 'elzr/vim-json', { 'for': 'json' } " JSON support

call plug#end() " Add plugins to &runtimepath

" ---------------------------------- "
" Syntastic
" ---------------------------------- "

" Recommended settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Custom settings
let s:condapylint = '/Users/fredrik/miniconda3/envs/pythondev_35/bin'
let $PATH .= ':' . s:condapylint
let g:syntastic_python_checkers = ['pylint']

" ---------------------------------- "
" Flake8
" ---------------------------------- "

" autocmd BufWritePost *.py call Flake8() " Perform check on save
" let g:flake8_show_in_gutter=1

" ---------------------------------- "
" NerdTree
" ---------------------------------- "

" Open NERDTree when Vim startsup and no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Open/close NERDTree with Ctrl-n
map <C-n> :NERDTreeToggle<CR>

" Ignore files in NERDTree
let NERDTreeIgnore=['\.pyc$', '\~$']

" ---------------------------------- "
" Airline
" ---------------------------------- "

let g:airline#extensions#tabline#enabled = 1
" let g:airline_powerline_fonts=1
" let g:airline_left_sep=''
" let g:airline_right_sep=''
" let g:airline_theme='base16'

" ---------------------------------- "
" Base16-vim
" ---------------------------------- "

let base16colorspace=256  " Access colors present in 256 colorspace"
" set t_Co=256 " Explicitly tell vim that the terminal supports 256 colors"

" colorscheme base16-ocean

" let zsh_theme=$THEME " Fetch the $THEME variable
" if zsh_theme != ""
"   execute "set background=".$BACKGROUND
"   execute "colorscheme ".$THEME
" endif

" highlight Comment cterm=italic
" highlight htmlArg cterm=italic
