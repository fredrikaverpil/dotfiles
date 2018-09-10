" nvim setup for macOS, Windows
" WARNING: this is a work in progress

" usage:
" 1. activate venv with neovim, jedi pip-installed
" 2. nvim-qt (if on Windows) or nvim

" known issues:
" - no rope
" - no great python syntax highlighting


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General: setting options
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible " not vi compatible
filetype off
" set backspace=2 " make backspace work like most other apps
set encoding=utf8
" set noerrorbells
" set visualbell
set number " show line numbers in nvim
set splitright  " make new vsplit appear to the right
set splitbelow  " make new split appear below


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General: assigning variables
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let term_program=$TERM_PROGRAM  " store the current terminal program name

" use the available python (python-mode, deoplete)
if has('win32')
  let g:python3_host_prog = 'python'  " win does not have python3 command
else
  let g:python3_host_prog = 'python3'
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General: key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if has('nvim')
  tnoremap <Esc> <C-\><C-n> " make ESC exit terminal
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => File type specific
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Python saving/reading settings (PEP8)
" au BufNewFile,BufRead *.py
"     \ set tabstop=4
"     \ set softtabstop=4
"     \ set shiftwidth=4
"     \ set textwidth=79
"     \ set expandtab
"     \ set autoindent
"     \ set fileformat=unix


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

call plug#begin('~/.vim/plugged')

" General
Plug 'scrooloose/nerdtree' " File browser
Plug 'jistr/vim-nerdtree-tabs' " Improves NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin' " git status in NERDtree
Plug 'kien/ctrlp.vim' " Search for file
Plug 'tpope/vim-fugitive' " Git commands
Plug 'vim-airline/vim-airline' " fancy statusline
Plug 'severin-lemaignan/vim-minimap' " minimap

" Theme
Plug 'kaicataldo/material.vim'

" Autocompletion
if has('nvim')
  " deoplete requires pip install neovim
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'davidhalter/jedi'  " requires pip install jedi
Plug 'zchee/deoplete-jedi'  " depoplete source for jedi

" Linting
Plug 'w0rp/ale' " Asynchronous Lint Engine (Vim 8.0)

" Python
" Plug 'python-mode/python-mode', { 'branch': 'develop' }
" Plug 'vim-scripts/indentpython.vim'
Plug 'tmhedberg/SimpylFold' " Improved folding, toggle with: za

call plug#end()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Python virtual environment setup
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" " python with virtualenv support
" py << EOF
" import os
" import sys
" if 'VIRTUAL_ENV' in os.environ:
"   project_base_dir = os.environ['VIRTUAL_ENV']
"   activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
"   execfile(activate_this, dict(__file__=activate_this))
" EOF


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:airline#extensions#tabline#enabled = 1  " tabs


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

let g:ale_enabled = 1
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 1
let g:ale_sign_column_always = 1
let g:ale_linters = {'python': ['flake8']}
let g:ale_fixers = {'python': ['yapf']}
let g:ale_warn_about_trailing_whitespace = 0
let g:ale_completion_enabled = 0


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: python-mode
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" let g:pymode_python = 'python3'
" let g:pymode_rope = 1
" let g:pymode_rope_show_doc_bind = '<C-c>d'
" let g:pymode_rope_completion = 1
" let g:pymode_rope_complete_on_dot = 1
" let g:pymode_rope_completion_bind = '<C-Space>'
" let g:pymode_rope_autoimport = 0
" let g:pymode_rope_goto_definition_bind = '<C-c>g'
" let g:pymode_rope_rename_bind = '<C-c>rr'
" let g:pymode_rope_organize_imports_bind = '<C-c>ro'
" let g:pymode_syntax_docstrings = 'pymode_syntax_all'


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: deoplete
"
" Deoplete requires:
" pip3 install neovim jedi
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#jedi#show_docstring = 1  " show docstrings in preview


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugin settings: material.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:material_theme_style = 'palenight'
let g:material_terminal_italics = 1

if has('nvim')
  "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

"For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
"Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
" < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
if has('termguicolors')
  if term_program != 'Apple_Terminal'
    set termguicolors
  endif
endif

set background=dark
colorscheme material
