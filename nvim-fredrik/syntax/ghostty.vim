if exists("b:current_syntax")
  finish
endif

syntax match ghosttyComment "#.*$"
syntax match ghosttyKey "^\s*[a-zA-Z0-9-]\+" nextgroup=ghosttyEquals
syntax match ghosttyEquals "\s*=\s*" contained nextgroup=ghosttyValue
syntax match ghosttyValue "[^#\n]*" contained

syntax match ghosttyHexColor "#[0-9a-fA-F]\{6}"

highlight default link ghosttyComment Comment
highlight default link ghosttyKey Identifier
highlight default link ghosttyEquals Operator
highlight default link ghosttyValue String
highlight default link ghosttyHexColor Special

let b:current_syntax = "ghostty"
