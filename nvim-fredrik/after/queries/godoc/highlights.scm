;; Treesitter highlight queries for godoc
;; These highlight structural elements (non-Go code regions)

;; Section headers (VARIABLES, FUNCTIONS, TYPES, CONSTANTS, etc.)
(section_header) @label

;; Package declaration line
(package_line) @keyword.import

;; Text lines remain unhighlighted for readability
(text_line) @none
