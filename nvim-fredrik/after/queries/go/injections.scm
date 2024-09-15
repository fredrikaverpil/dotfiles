; extends

; copied (with thanks) from https://github.com/ray-x/go.nvim/blob/master/after/queries/go/injections.scm

; sql

; inject sql in single line strings
; e.g. db.GetContext(ctx, "SELECT * FROM users WHERE name = 'John'")

; neovim 0.10
([
  (interpreted_string_literal)
  (raw_string_literal)
  ] @injection.content
 (#match? @injection.content "(SELECT|select|INSERT|insert|UPDATE|update|DELETE|delete).+(FROM|from|INTO|into|VALUES|values|SET|set).*(WHERE|where|GROUP BY|group by)?")
 (#offset! @injection.content 0 1 0 -1)
(#set! injection.language "sql"))



; json

; jsonStr := `{"foo": "bar"}`

; nvim 0.10

(const_spec
  name: (identifier)
  value: (expression_list (raw_string_literal) @injection.content
   (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
   (#offset! @injection.content 0 1 0 -1)
   (#set! injection.language "json")))

(short_var_declaration
    left: (expression_list (identifier))
    right: (expression_list (raw_string_literal) @injection.content)
  (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "json"))

(var_spec
  name: (identifier)
  value: (expression_list (raw_string_literal) @injection.content
   (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
   (#offset! @injection.content 0 1 0 -1)
   (#set! injection.language "json")))
