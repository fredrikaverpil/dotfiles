; extends

; copied (with thanks) from https://github.com/ray-x/go.nvim/blob/master/after/queries/go/injections.scm
; sql: inject when a string looks structurally like a SQL query
; e.g. db.GetContext(ctx, "SELECT * FROM users WHERE name = 'John'")
([
  (interpreted_string_literal_content)
  (raw_string_literal_content)
] @injection.content
  (#match? @injection.content
    "(SELECT|select|INSERT|insert|UPDATE|update|DELETE|delete).+(FROM|from|INTO|into|VALUES|values|SET|set).*(WHERE|where|GROUP BY|group by)?")
  (#set! injection.language "sql"))

; sql: inject when a string is explicitly marked or contains a DDL keyword
; (data-query strings are already covered structurally by the #match? above)
([
  (interpreted_string_literal_content)
  (raw_string_literal_content)
] @injection.content
  (#any-contains? @injection.content
    "-- sql" "--sql"
    "ADD CONSTRAINT" "ALTER COLUMN" "ALTER TABLE" "CREATE INDEX"
    "FOREIGN KEY" "PRIMARY KEY" "TRUNCATE TABLE")
  (#set! injection.language "sql"))

; json: inject into backtick string literals that look like a JSON object
; e.g. jsonStr := `{"foo": "bar"}`
(const_spec
  name: (identifier)
  value: (expression_list
    (raw_string_literal
      (raw_string_literal_content) @injection.content)
    (#lua-match? @injection.content "^[\n\t ]*{.*}[\n\t ]*$")
    (#set! injection.language "json")))

(short_var_declaration
  left: (expression_list
    (identifier))
  right: (expression_list
    (raw_string_literal
      (raw_string_literal_content) @injection.content))
  (#lua-match? @injection.content "^[\n\t ]*{.*}[\n\t ]*$")
  (#set! injection.language "json"))

(var_spec
  name: (identifier)
  value: (expression_list
    (raw_string_literal
      (raw_string_literal_content) @injection.content)
    (#lua-match? @injection.content "^[\n\t ]*{.*}[\n\t ]*$")
    (#set! injection.language "json")))
