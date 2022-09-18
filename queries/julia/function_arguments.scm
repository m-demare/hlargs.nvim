(parameter_list
  [
    (identifier) @argname
    (optional_parameter
      (identifier) @argname)
    (typed_parameter
      . (identifier) @argname)
])

(spread_parameter
  [
    (identifier) @argname
    (optional_parameter
      (identifier) @argname)
    (typed_parameter
      . (identifier) @argname)
])

(keyword_parameters
  [
    (identifier) @argname
    (optional_parameter
      (identifier) @argname)
    (typed_parameter
      . (identifier) @argname)
])

(function_expression
    . (identifier) @argname)

(do_clause
  [
    (identifier) @argname
    (typed_expression
      . (identifier) @argname)
    (bare_tuple_expression
      (identifier) @argname)
])

(assignment_expression
  . (call_expression
    (argument_list
      [
        (identifier) @argname
        (typed_expression
          . (identifier) @argname)
        (spread_expression
          (identifier) @argname)
])))

