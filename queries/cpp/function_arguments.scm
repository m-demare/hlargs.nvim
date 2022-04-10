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
])

; There has to be a better way to do this

