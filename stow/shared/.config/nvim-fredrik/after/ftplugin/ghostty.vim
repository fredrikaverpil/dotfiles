" Vim filetype plugin file
" Language: Ghostty config file
" Maintainer: Ghostty <https://github.com/ghostty-org/ghostty>
"
" THIS FILE IS AUTO-GENERATED

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal commentstring=#\ %s
setlocal iskeyword+=-

" Use syntax keywords for completion
setlocal omnifunc=syntaxcomplete#Complete

let b:undo_ftplugin = 'setl cms< isk< ofu<'
