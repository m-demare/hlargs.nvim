(function_definition
  parameters: (parameters
    [
      (identifier) @argname
      (list_splat_pattern
        (identifier) @argname)
      (dictionary_splat_pattern
        (identifier) @argname)
      (default_parameter
        (identifier) @argname)
      (typed_parameter
        [
          (identifier) @argname
          (list_splat_pattern
            (identifier) @argname)
          (dictionary_splat_pattern
            (identifier) @argname)
        ])
      (typed_default_parameter
        (identifier) @argname)
    ]))
(lambda
  parameters: (lambda_parameters
    [
      (identifier) @argname
      (list_splat_pattern
        (identifier) @argname)
      (dictionary_splat_pattern
        (identifier) @argname)
      (default_parameter
        (identifier) @argname)
    ]))
(except_clause
  (as_pattern
    (as_pattern_target
      (identifier) @catch)))

