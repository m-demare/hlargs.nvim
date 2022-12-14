((_
  (_
    (_
      (identifier) @var))) @ignore
      ; Ignore struct initialization ( {foo: bar} )
      (#not-lua-match? @ignore "^%{[%s]*[%a][%a%d_]*[%s]*:.*%}$")
)

(literal_value
  (keyed_element
    (literal_element
      (identifier))
    (literal_element
      (identifier) @var)))
