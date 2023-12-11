(function_declarator
  (parameter_list
    [
      (optional_parameter_declaration
        (identifier) @argname)
      (parameter_declaration
        (identifier) @argname)
      (optional_parameter_declaration
        (_
            (identifier) @argname))
      (parameter_declaration
        (_
            (identifier) @argname))
      (optional_parameter_declaration
        (_
          (_
            (identifier) @argname)))
      (parameter_declaration
        (_
          (_
            (identifier) @argname)))
      (optional_parameter_declaration
        (_
          (_
            (_
              (identifier) @argname))))
      (parameter_declaration
        (_
          (_
            (_
              (identifier) @argname))))
  ]))
(abstract_function_declarator
  (parameter_list
    [
      (optional_parameter_declaration
        (identifier) @argname)
      (parameter_declaration
        (identifier) @argname)
      (optional_parameter_declaration
        (_
            (identifier) @argname))
      (parameter_declaration
        (_
            (identifier) @argname))
      (optional_parameter_declaration
        (_
          (_
            (identifier) @argname)))
      (parameter_declaration
        (_
          (_
            (identifier) @argname)))
      (optional_parameter_declaration
        (_
          (_
            (_
              (identifier) @argname))))
      (parameter_declaration
        (_
          (_
            (_
              (identifier) @argname))))
  ]))

; There has to be a better way to do this

(catch_clause
  parameters: (parameter_list
    (parameter_declaration
      declarator: (_
        (identifier) @catch))))
