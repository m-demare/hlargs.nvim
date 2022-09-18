((_
  (identifier) @var) @ignore
  ; Ignore field accessing (foo.bar)
  (#not-lua-match? @ignore "^[^%.]+%.[^%.]+$")
)
; Only take the leftmost identifier in field accessing
(field_expression
  . (identifier) @var)


