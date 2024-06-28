((_
  (identifier) @var) @ignore
  ; Ignore dataset indexing (foo$bar)
  (#not-lua-match? @ignore "^[%a][%a0-9\._]*\$[%a0-9\._\$]+$")
)
; Only take the leftmost identifier in dataset indexing
(extract_operator
  lhs: (identifier) @var)

