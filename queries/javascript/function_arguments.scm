(formal_parameters
    (identifier) @argname)
(formal_parameters
    (rest_pattern
      (identifier) @argname))
(formal_parameters
    (array_pattern
      (identifier) @argname))
(formal_parameters
    (object_pattern
      (shorthand_property_identifier_pattern) @argname))
(formal_parameters
  (object_pattern
    (pair_pattern
      value: (identifier) @argname)))
(formal_parameters
  (assignment_pattern
    left: (identifier) @definition.parameter))
(arrow_function
  . parameter: (identifier) @argname)
(catch_clause
  . parameter: (identifier) @catch)

