" Sections:
"    -> General
"    -> Plugins
"    -> Plugin settings: Airline
"    -> Plugin settings: NERDTree
"    -> Plugin settings: Ale
"    -> Plugin settings: Python Mode
"    -> Plugin settings: vim-indent-guides
"    -> Colors and Fonts
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible " not vi compatible
set backspace=2 " make backspace work like most other apps
set encoding=utf8
set number " show line numbers
" set noerrorbells
" set visualbell


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

call plug#begin('~/.vim/plugged')

" Color schemes
Plug 'kristijanhusak/vim-hybrid-material' " Material theme (hybrid)
Plug 'jdkanani/vim-material-theme' " Material theme (works with iTerm2)
Plug 'chriskempson/base16-vim' " Colorschemes

" General
Plug 'tpope/vim-sensible'
Plug 'vim-indent-guides' " Indentation guides
Plug 'scrooloose/nerdtree' " File browser
Plug 'jistr/vim-nerdtree-tabs' " Improves NERDTree
Plug 'kien/ctrlp.vim' " Search for file
Plug 'tpope/vim-fugitive' " Git commands
Plug 'vim-airline/vim-airline' " fancy statusline
Plug 'vim-airline/vim-airline-themes' " themes for vim-airline
Plug 'severin-lemaignan/vim-minimap' " minimap

" Linting
Plug 'w0rp/ale' " Asynchronous Lint Engine (Vim 8.0)

" Python
Plug 'davidhalter/jedi-vim' " Jedi Autocompletion
Plug 'klen/python-mode', {'do': ':helptags ~/.vim/doc/'}  " Python Mode

" Other languages
Plug 'elzr/vim-json', { 'for': 'json' } " JSON support

call plug#end()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts=0
" let g:airline_left_sep=''
" let g:airline_right_sep=''
" let g:airline_theme='base16'
let g:airline_theme='hybrid'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: NERDTree
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Open NERDTree when Vim startsup and no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Open/close NERDTree with Ctrl-n
map <C-n> :NERDTreeToggle<CR>

" Ignore files in NERDTree
let NERDTreeIgnore=['\.pyc$', '\~$']


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: Ale
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

filetype off
let &runtimepath.=',~/.vim/plugged/ale'
filetype plugin on

" Disable linting for Python (use Python Mode instead)
let g:ale_python_pylint_executable='/Users/fredrik/miniconda3/envs/pythondev_35/bin/pylint'

let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 1
let g:ale_sign_column_always = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: Python Mode
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" let g:pymode = 1 " Enable Python Mode plugin
" let g:pymode_trim_whitespaces = 1
" let g:pymode_python = 'python3' " Python 3 syntax checking
let g:pymode_folding = 0

let g:pymode_lint = 0
let g:pymode_lint_on_write = 1
let g:pymode_lint_unmodified = 0
let g:pymode_lint_on_fly = 1
let g:pymode_lint_checkers = ['pylint', 'pep8']
" let g:pymode_lint_ignore = "E501,W"

let g:pymode_rope = 0


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: vim-indent-guides
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" let g:indent_guides_auto_colors = 1
" hi IndentGuidesOdd  ctermbg=white
" hi IndentGuidesEven ctermbg=lightgrey


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable syntax highlighting
syntax enable

set t_Co=256

set background=dark
colorscheme hybrid_material
" colorscheme material-theme
