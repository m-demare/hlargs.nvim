(function_definition
  parameters: (parameters
    [
      (identifier) @argname
      (list_splat_pattern
        (identifier) @argname)
      (dictionary_splat_pattern
        (identifier) @argname)
    ]))
(function_definition
  parameters: (parameters
    (default_parameter
      [
        (identifier) @argname
      ])))
(function_definition
  parameters: (parameters
    (typed_parameter
      [
        (identifier) @argname
        (list_splat_pattern
          (identifier) @argname)
        (dictionary_splat_pattern
          (identifier) @argname)
      ])))
(function_definition
  parameters: (parameters
    (typed_default_parameter
      [
        (identifier) @argname
      ])))
(lambda
  parameters: (lambda_parameters
    [
      (identifier) @argname
      (list_splat_pattern
        (identifier) @argname)
      (dictionary_splat_pattern
        (identifier) @argname)
    ]))
