# Used by "mix format"
locals_without_parens = [
  assert!: 1,
  refute!: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
