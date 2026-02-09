(parameter
  name: (simple_identifier) @argname
  (#not-eq? @argname "_"))
(lambda_parameter
  name: (simple_identifier) @argname
  (#not-eq? @argname "_"))
(catch_block
  error: (pattern
    (simple_identifier) @catch))
