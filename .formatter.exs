locals_without_parens = [
  assert!: 1,
  refute!: 1,
  assert_raise: 1,
  assert_lists_equal: 2,
  assert_lists_equal: 3,
  assert_map_in_list: 3,
  assert_maps_equal: 3,
  assert_struct_in_list: 3,
  assert_structs_equal: 3,
  assert_all_have_value: 3,
  assert_changes_file: 3,
  assert_creates_file: 2,
  assert_deletes_file: 2,
  assert_receive_only: 2,
  assert_receive_only: 1,
  assert_async: 2,
  assert_response_equals: 3,
  assert_response_equals: 2,
  assert_response_matches: 4,
  assert_response_matches: 3,
  assert_response_matches: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
