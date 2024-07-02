defmodule Assertions do
  @moduledoc """
  Helpful assertions with great error messages to help you write better tests.
  """

  alias Assertions.Comparisons

  @type comparison :: (any, any -> boolean | no_return)
  @type comparison_or_list :: comparison | [any]

  @doc """
  Asserts that the return value of the given expression is `true`.

  This is different than the normal behavior of `assert` since that will pass
  for any value that is "truthy" (anything other than `false` or `nil`). This is
  a stricter assertion, only passing if the value is `true`. This is very
  helpful for testing values that are expected to only be booleans.

  This will also check specifically for `nil` values when using `>`, `<`, `>=`
  or `<=` since those frequently have unintended behavior.

      iex> assert!(:a == :a)
      true
      iex> assert!(10 > 5)
      true
      iex> map = %{key: true}
      iex> assert!(map.key)
      true

  """
  @spec assert!(Macro.expr()) :: true | no_return
  defmacro assert!({operator, _, [left, right]} = assertion)
           when operator in [:>, :<, :>=, :<=] do
    expr = escape_quoted(:assert!, assertion)
    {args, value} = extract_args(assertion, __CALLER__)

    quote do
      left = unquote(left)
      right = unquote(right)

      if is_nil(left) or is_nil(right) do
        assert false,
          left: left,
          right: right,
          expr: unquote(expr),
          message:
            "`nil` is not allowed as an argument to `#{unquote(operator)}` when using `assert!`"
      else
        value = unquote(value)

        unless value == true do
          raise ExUnit.AssertionError,
            args: unquote(args),
            expr: unquote(expr),
            message: "Expected `true`, got #{inspect(value)}"
        end

        true
      end
    end
  end

  defmacro assert!(assertion) do
    {args, value} = extract_args(assertion, __CALLER__)

    quote do
      value = unquote(value)

      unless value == true do
        raise ExUnit.AssertionError,
          args: unquote(args),
          expr: unquote(escape_quoted(:assert!, assertion)),
          message: "Expected `true`, got #{inspect(value)}"
      end

      value
    end
  end

  @doc """
  Asserts that the return value of the given expression is `false`.

  This is different than the normal behavior of `refute/1` since that will pass
  if the value is either `false` or `nil`. This is a stricter assertion, only
  passing if the value is `false`. This is very helpful for testing values that
  are expected to only be booleans.

  This will also check specifically for `nil` values when using `>`, `<`, `>=`
  or `<=` since those frequently have unintended behavior.

      iex> refute!(5 > 10)
      true
      iex> refute!("a" == "A")
      true

  """
  @spec refute!(Macro.expr()) :: true | no_return
  defmacro refute!({operator, _, [left, right]} = assertion)
           when operator in [:>, :<, :>=, :<=] do
    expr = escape_quoted(:refute!, assertion)
    {args, value} = extract_args(assertion, __CALLER__)

    quote do
      left = unquote(left)
      right = unquote(right)

      if is_nil(left) or is_nil(right) do
        raise ExUnit.AssertionError,
          args: unquote(args),
          expr: unquote(expr),
          left: left,
          right: right,
          message:
            "`nil` is not allowed as an argument to `#{unquote(operator)}` when using `refute!`"
      else
        value = unquote(value)

        unless value == false do
          raise ExUnit.AssertionError,
            args: unquote(args),
            expr: unquote(expr),
            left: left,
            right: right,
            message: "Expected `false`, got #{inspect(value)}"
        end

        true
      end
    end
  end

  defmacro refute!(assertion) do
    {args, value} = extract_args(assertion, __CALLER__)

    quote do
      value = unquote(value)

      unless value == false do
        raise ExUnit.AssertionError,
          args: unquote(args),
          expr: unquote(escape_quoted(:refute!, assertion)),
          message: "Expected `false`, got #{inspect(value)}"
      end

      true
    end
  end

  @doc """
  Asserts that a function should raise an exception, but without forcing the user to specify which
  exception should be raised. This is essentially a less-strict version of `assert_raise/2`.

      iex> assert_raise(fn -> String.to_existing_atom("asleimflisesliseli") end)
      true
  """
  @spec assert_raise(fun()) :: true | no_return
  def assert_raise(func) do
    try do
      func.()
      ExUnit.Assertions.flunk("Expected exception but nothing was raised")
    rescue
      e in ExUnit.AssertionError ->
        raise e

      _ ->
        true
    end
  end

  @doc """
  Asserts that two lists contain the same elements without asserting they are
  in the same order.

      iex> assert_lists_equal([1, 2, 3], [1, 3, 2])
      true

  """
  @spec assert_lists_equal(list, list) :: true | no_return
  defmacro assert_lists_equal(left, right) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right))
        end
      )

    quote do
      {left_diff, right_diff, equal?} = Comparisons.compare_lists(unquote(left), unquote(right))

      if equal? do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: "Comparison of each element failed!"
      end
    end
  end

  @doc """
  Asserts that two lists contain the same elements without asserting they are
  in the same order.

  The given comparison function determines if the two lists are considered
  equal.

      iex> assert_lists_equal(["dog"], ["cat"], &(is_binary(&1) and is_binary(&2)))
      true

  """
  @spec assert_lists_equal(list, list, comparison) :: true | no_return
  defmacro assert_lists_equal(left, right, comparison) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right), unquote(comparison))
        end
      )

    quote do
      {left_diff, right_diff, equal?} =
        Comparisons.compare_lists(unquote(left), unquote(right), unquote(comparison))

      if equal? do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right), unquote(comparison)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: "Comparison of each element failed!"
      end
    end
  end

  @doc """
  Asserts that a `map` is in the given `list`.

  This is either done by passing a list of `keys`, and the values at those keys
  will be compared to determine if the map is in the list.

      iex> map = %{first: :first, second: :second}
      iex> list = [%{first: :first, second: :second, third: :third}]
      iex> keys = [:first, :second]
      iex> assert_map_in_list(map, list, keys)
      true

  Or this is done by passing a comparison function that determines if the map
  is in the list.

  If using a comparison function, the `map` is the first argument to that
  function, and the elements in the list are the second argument.

      iex> map = %{first: :first, second: :second}
      iex> list = [%{"first" => :first, "second" => :second, "third" => :third}]
      iex> comparison = &(&1.first == &2["first"] and &1.second == &2["second"])
      iex> assert_map_in_list(map, list, comparison)
      true

  """
  @spec assert_map_in_list(map, [map], comparison_or_list) :: true | no_return
  defmacro assert_map_in_list(map, list, keys_or_comparison) do
    assertion =
      assertion(
        quote do
          assert_map_in_list(unquote(map), unquote(list), unquote(keys_or_comparison))
        end
      )

    quote do
      keys_or_comparison = unquote(keys_or_comparison)

      positive = fn keys ->
        map = Map.take(unquote(map), keys)
        list = Enum.map(unquote(list), &Map.take(&1, keys))
        keys = unquote(stringify_list(keys_or_comparison))
        message = "Map matching the values for keys `#{keys}` not found"
        {Enum.member?(list, map), map, list, message}
      end

      negative = fn comparison ->
        map = unquote(map)
        list = unquote(list)
        message = "Map not found in list using given comparison"

        {Enum.any?(list, &comparison.(map, &1)), map, list, message}
      end

      {in_list?, map, list, message} =
        Comparisons.when_is_list(keys_or_comparison, positive, negative)

      if in_list? do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(map), unquote(list)],
          left: map,
          right: list,
          expr: unquote(assertion),
          message: message
      end
    end
  end

  @doc """
  Asserts that two maps are equal.

  Equality can be determined in two ways. First, by passing a list of keys. The
  values at these keys will be used to determine if the maps are equal.

      iex> left = %{first: :first, second: :second, third: :third}
      iex> right = %{first: :first, second: :second, third: :fourth}
      iex> keys = [:first, :second]
      iex> assert_maps_equal(left, right, keys)
      true

  The second is to pass a comparison function that returns a boolean that
  determines if the maps are equal. When using a comparison function, the first
  argument to the function is the `left` map and the second argument is the
  `right` map.

      iex> left = %{first: :first, second: :second, third: :third}
      iex> right = %{"first" => :first, "second" => :second, "third" => :fourth}
      iex> comparison = &(&1.first == &2["first"] and &1.second == &2["second"])
      iex> assert_maps_equal(left, right, comparison)
      true

  """
  @spec assert_maps_equal(map, map, comparison_or_list) :: true | no_return
  defmacro assert_maps_equal(left, right, keys_or_comparison) do
    assertion =
      assertion(
        quote do
          assert_maps_equal(unquote(left), unquote(right), unquote(keys_or_comparison))
        end
      )

    quote do
      keys_or_comparison = unquote(keys_or_comparison)
      left = unquote(left)
      right = unquote(right)

      positive = fn keys ->
        left = Map.take(left, keys)
        right = Map.take(right, keys)
        {left_diff, right_diff, equal?} = Comparisons.compare_maps(left, right)
        message = "Values for #{unquote(stringify_list(keys_or_comparison))} not equal!"
        {left_diff, right_diff, equal?, message}
      end

      negative = fn comparison ->
        {left, right, comparison.(left, right), "Maps not equal using given comparison"}
      end

      {left_diff, right_diff, equal?, message} =
        Comparisons.when_is_list(keys_or_comparison, positive, negative)

      if equal? do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: message
      end
    end
  end

  @doc """
  Asserts that the `struct` is present in the `list`.

  There are two ways to make this comparison. First is to pass a list of keys
  to use to compare the `struct` to the structs in the `list`.

      iex> now = DateTime.utc_now()
      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> keys = [:year, :month, :day]
      iex> assert_struct_in_list(now, list, keys)
      true

  The second way to use this assertion is to pass a comparison function.

  When using a comparison function, the `struct` is the first argument to that
  function and the elements in the `list` will be the second argument.

      iex> now = DateTime.utc_now()
      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> assert_struct_in_list(now, list, &(&1.year == &2.year))
      true

  """
  @spec assert_struct_in_list(struct, [struct], comparison_or_list) :: true | no_return
  defmacro assert_struct_in_list(struct, list, keys_or_comparison) do
    assertion =
      assertion(
        quote do
          assert_struct_in_list(unquote(struct), unquote(list), unquote(keys_or_comparison))
        end
      )

    quote do
      struct = unquote(struct)
      list = unquote(list)
      keys_or_comparison = unquote(keys_or_comparison)

      positive = fn starting ->
        keys = [:__struct__ | keys_or_comparison]
        struct = Map.take(struct, keys)
        list = Enum.map(list, &Map.take(&1, keys))

        {struct in list,
          "Struct matching the values for keys #{unquote(stringify_list(keys_or_comparison))} not found"}
      end

      negative = fn comparison ->
        {Enum.any?(list, &comparison.(struct, &1)),
          "Struct not found in list using the given comparison"}
      end

      {in_list?, message} =
        Comparisons.when_is_list(keys_or_comparison, positive, negative)

      if in_list? do
        true
      else
        raise ExUnit.AssertionError,
          args: [struct, list, keys_or_comparison],
          left: struct,
          right: list,
          expr: unquote(assertion),
          message: message
      end
    end
  end

  @doc """
  Asserts that two structs are equal.

  Equality can be determined in two ways. First, by passing a list of keys. The
  values at these keys and the type of the structs will be used to determine if
  the structs are equal.

      iex> left = DateTime.utc_now()
      iex> right = DateTime.utc_now()
      iex> keys = [:year, :minute]
      iex> assert_structs_equal(left, right, keys)
      true

  The second is to pass a comparison function that returns a boolean that
  determines if the structs are equal. When using a comparison function, the
  first argument to the function is the `left` struct and the second argument
  is the `right` struct.

      iex> left = DateTime.utc_now()
      iex> right = DateTime.utc_now()
      iex> comparison = &(&1.year == &2.year and &1.minute == &2.minute)
      iex> assert_structs_equal(left, right, comparison)
      true

  """
  @spec assert_structs_equal(struct, struct, comparison_or_list) :: true | no_return
  defmacro assert_structs_equal(left, right, keys_or_comparison) do
    assertion =
      assertion(
        quote do
          assert_structs_equal(unquote(left), unquote(right), unquote(keys_or_comparison))
        end
      )

    quote do
      left = unquote(left)
      right = unquote(right)
      keys_or_comparison = unquote(keys_or_comparison)

      positive = fn starting ->
        keys = [:__struct__ | starting]
        left = Map.take(left, keys)
        right = Map.take(right, keys)
        message = "Values for #{unquote(stringify_list(keys_or_comparison))} not equal!"
        {left_diff, right_diff, equal?} = Comparisons.compare_maps(left, right)
        {left_diff, right_diff, equal?, message}
      end

      negative = fn comparison ->
        {left_diff, right_diff, equal?} =
          case comparison.(left, right) do
            {_, _, equal?} = result when is_boolean(equal?) -> result
            true_or_false when is_boolean(true_or_false) -> {left, right, true_or_false}
          end

        {left_diff, right_diff, equal?, "Comparison failed!"}
      end

      {left_diff, right_diff, equal?, message} =
        Comparisons.when_is_list(keys_or_comparison, positive, negative)

      if equal? do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: message
      end
    end
  end

  @doc """
  Asserts that all maps, structs or keyword lists in `list` have the same
  `value` for `key`.

      iex> assert_all_have_value([%{key: :value}, %{key: :value, other: :key}], :key, :value)
      true

      iex> assert_all_have_value([[key: :value], [key: :value, other: :key]], :key, :value)
      true

      iex> assert_all_have_value([[key: :value], %{key: :value, other: :key}], :key, :value)
      true

  """
  @spec assert_all_have_value(list(map | struct | Keyword.t()), any, any) :: true | no_return
  defmacro assert_all_have_value(list, key, value) do
    assertion =
      assertion(
        quote do
          assert_all_have_value(unquote(list), unquote(key), unquote(value))
        end
      )

    quote do
      key = unquote(key)
      value = unquote(value)

      list =
        Enum.map(unquote(list), fn
          map when is_map(map) -> Map.take(map, [key])
          list -> [{key, Keyword.get(list, key, :key_not_present)}]
        end)

      diff =
        Enum.reject(list, fn
          map when is_map(map) -> Map.equal?(map, %{key => value})
          list -> Keyword.equal?(list, [{key, value}])
        end)

      if diff == [] do
        true
      else
        raise ExUnit.AssertionError,
          args: [unquote(list), unquote(key), unquote(value)],
          left: %{key => value},
          right: diff,
          expr: unquote(assertion),
          message: "Values for `#{inspect(key)}` not equal in all elements!"
      end
    end
  end

  @doc """
  Asserts that the file at `path` is changed to match `comparison` after
  executing the given `expression`.

  If the file matches `comparison` before executing `expr`, this assertion will
  fail. The file does not have to exist before executing `expr` in order for
  this assertion to pass.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> result = assert_changes_file(path, "hi") do
      iex>   File.mkdir_p!(Path.dirname(path))
      iex>   File.write(path, "hi")
      iex> end
      iex> File.rm_rf!(Path.dirname(path))
      iex> result
      true

  """
  @spec assert_changes_file(Path.t(), String.t() | Regex.t(), Macro.expr()) :: true | no_return
  defmacro assert_changes_file(path, comparison, [do: expr] = expression) do
    assertion =
      assertion(
        quote do
          assert_changes_file(unquote(path), unquote(comparison), unquote(expression))
        end
      )

    quote do
      path = unquote(path)
      comparison = unquote(comparison)
      args = [unquote(path), unquote(comparison)]

      {match_before?, start_file} =
        case File.read(path) do
          {:ok, start_file} -> {start_file =~ comparison, start_file}
          _ -> {false, nil}
        end

      if match_before? do
        raise ExUnit.AssertionError,
          args: args,
          expr: unquote(assertion),
          left: start_file,
          right: unquote(comparison),
          message: "File #{inspect(path)} matched `#{inspect(comparison)}` before executing expr!"
      else
        unquote(expr)

        end_file =
          case File.read(path) do
            {:ok, end_file} ->
              end_file

            _ ->
              raise ExUnit.AssertionError,
                args: args,
                expr: unquote(assertion),
                message: "File #{inspect(path)} does not exist after executing expr!"
          end

        if end_file =~ comparison do
          true
        else
          raise ExUnit.AssertionError,
            args: args,
            left: end_file,
            right: comparison,
            expr: unquote(assertion),
            message: "File did not change to match comparison after expr!"
        end
      end
    end
  end

  @doc """
  Asserts that the file at `path` is created after executing the given
  `expression`.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> File.mkdir_p!(Path.dirname(path))
      iex> result = assert_creates_file path do
      iex>   File.write(path, "hi")
      iex> end
      iex> File.rm_rf!(Path.dirname(path))
      iex> result
      true

  """
  @spec assert_creates_file(Path.t(), Macro.expr()) :: true | no_return
  defmacro assert_creates_file(path, [do: expr] = expression) do
    assertion =
      assertion(
        quote do
          assert_creates_file(unquote(path), unquote(expression))
        end
      )

    quote do
      path = unquote(path)
      args = [unquote(path)]

      if File.exists?(path) do
        raise ExUnit.AssertionError,
          args: args,
          expr: unquote(assertion),
          message: "File #{inspect(path)} existed before executing expr!"
      else
        unquote(expr)

        if File.exists?(path) do
          true
        else
          raise ExUnit.AssertionError,
            args: args,
            expr: unquote(assertion),
            message: "File #{inspect(path)} does not exist after executing expr!"
        end
      end
    end
  end

  @doc """
  Asserts that the file at `path` is deleted after executing the given
  `expression`.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> File.mkdir_p!(Path.dirname(path))
      iex> File.write(path, "hi")
      iex> assert_deletes_file path do
      iex>   File.rm_rf!(Path.dirname(path))
      iex> end
      true

  """
  @spec assert_deletes_file(Path.t(), Macro.expr()) :: true | no_return
  defmacro assert_deletes_file(path, [do: expr] = expression) do
    assertion =
      assertion(
        quote do
          assert_deletes_file(unquote(path), unquote(expression))
        end
      )

    quote do
      path = unquote(path)
      args = [unquote(path)]

      if !File.exists?(path) do
        raise ExUnit.AssertionError,
          args: args,
          expr: unquote(assertion),
          message: "File #{inspect(path)} did not exist before executing expr!"
      else
        unquote(expr)

        if !File.exists?(path) do
          true
        else
          raise ExUnit.AssertionError,
            args: args,
            expr: unquote(assertion),
            message: "File #{inspect(path)} exists after executing expr!"
        end
      end
    end
  end

  @doc """
  Tests that a message matching the given `pattern`, and only that message, is
  received before the given `timeout`, specified in milliseconds.

  The optional second argument is a timeout for the `receive` to wait for the
  expected message, and defaults to 100ms.

  ## Examples

      iex> send(self(), :hello)
      iex> assert_receive_only(:hello)
      true

      iex> send(self(), [:hello])
      iex> assert_receive_only([_])
      true

      iex> a = :hello
      iex> send(self(), :hello)
      iex> assert_receive_only(^a)
      true

      iex> send(self(), :hello)
      iex> assert_receive_only(a when is_atom(a))
      iex> a
      :hello

      iex> send(self(), %{key: :value})
      iex> assert_receive_only(%{key: value} when is_atom(value))
      iex> value
      :value

  If a message is received after the assertion has matched a message to the
  given pattern, but the second message is received before the timeout, that
  second message is ignored and the assertion returns `true`.

  This assertion only tests that the message that matches the given pattern was
  the first message in the process inbox, and that nothing was sent between the
  sending the message that matches the pattern and when `assert_receive_only/2`
  was called.

      iex> Process.send_after(self(), :hello, 20)
      iex> Process.send_after(self(), :hello_again, 50)
      iex> assert_receive_only(:hello, 100)
      true

  """
  @spec assert_receive_only(Macro.expr(), non_neg_integer) :: any | no_return
  defmacro assert_receive_only(pattern, timeout \\ 100) do
    binary = Macro.to_string(pattern)
    caller = __CALLER__

    assertion =
      assertion(
        quote do
          assert_receive_only(unquote(pattern), unquote(timeout))
        end
      )

    expanded_pattern = expand_pattern(pattern, caller)
    vars = collect_vars_from_pattern(expanded_pattern)

    {timeout, pattern, failure_message} =
      if function_exported?(ExUnit.Assertions, :__timeout__, 4) do
        assert_receive_data(:old, pattern, expanded_pattern, timeout, caller, vars, binary)
      else
        assert_receive_data(:new, pattern, expanded_pattern, timeout, caller, vars, binary)
      end

    bind_variables =
      quote do
        {received, unquote(vars)}
      end

    quote do
      timeout = unquote(timeout)

      unquote(bind_variables) =
        receive do
          unquote(pattern) ->
            result = unquote(bind_variables)

            receive do
              thing ->
                raise ExUnit.AssertionError,
                  expr: unquote(assertion),
                  message: "`#{inspect(thing)}` was also in the mailbox"
            after
              0 ->
                result
            end

          random_thing ->
            raise ExUnit.AssertionError,
              expr: unquote(assertion),
              message: "Received unexpected message: `#{inspect(random_thing)}`"
        after
          timeout -> flunk(unquote(failure_message))
        end

      true
    end
  end

  defp assert_receive_data(:old, pattern, _, timeout, caller, vars, binary) do
    pins = collect_pins_from_pattern(pattern, Macro.Env.vars(caller))
    {pattern, pattern_finder} = patterns(pattern, vars)

    timeout =
      if is_integer(timeout) do
        timeout
      else
        quote do: ExUnit.Assertions.__timeout__(unquote(timeout))
      end

    failure_message =
      quote do
        ExUnit.Assertions.__timeout__(
          unquote(binary),
          unquote(pins),
          unquote(pattern_finder),
          timeout
        )
      end

    {timeout, pattern, failure_message}
  end

  defp assert_receive_data(:new, pattern, expanded_pattern, timeout, caller, vars, _) do
    code = escape_quoted(:assert_receive_only, pattern)
    pins = collect_pins_from_pattern(expanded_pattern, Macro.Env.vars(caller))
    {pattern, pattern_finder} = patterns(expanded_pattern, vars)

    timeout =
      if function_exported?(ExUnit.Assertions, :__timeout__, 2) do
        quote do
          ExUnit.Assertions.__timeout__(unquote(timeout), :assert_receive_timeout)
        end
      else
        quote do
          ExUnit.Assertions.__timeout__(unquote(timeout))
        end
      end

    failure_message =
      quote do
        ExUnit.Assertions.__timeout__(
          unquote(Macro.escape(expanded_pattern)),
          unquote(code),
          unquote(pins),
          unquote(pattern_finder),
          timeout
        )
      end

    {timeout, pattern, failure_message}
  end

  defp patterns(pattern, vars) do
    pattern =
      case pattern do
        {:when, meta, [left, right]} ->
          {:when, meta, [quote(do: unquote(left) = received), right]}

        left ->
          quote(do: unquote(left) = received)
      end

    quoted_pattern =
      quote do
        case message do
          unquote(pattern) ->
            _ = unquote(vars)
            true

          _ ->
            false
        end
      end

    pattern_finder =
      quote do
        fn message ->
          unquote(suppress_warning(quoted_pattern))
        end
      end

    {pattern, pattern_finder}
  end

  @doc """
  Asserts that some condition succeeds within a given timeout (in milliseconds)
  and sleeps for a given time between checks of the given condition (in
  milliseconds).

  This is helpful for testing that asynchronous operations have succeeded within
  a certain timeframe. This method of testing asynchronous operations is less
  reliable than other methods, but it can often be more useful at an integration
  level.

      iex> Process.send_after(self(), :hello, 50)
      iex> assert_async do
      iex>   assert_received :hello
      iex> end
      true

      iex> Process.send_after(self(), :hello, 50)
      iex> assert_async(timeout: 75, sleep_time: 40) do
      iex>   assert_received :hello
      iex> end
      true

      iex> Process.send_after(self(), :hello, 50)
      iex> try do
      iex>   assert_async(timeout: 4, sleep_time: 2) do
      iex>     assert_received :hello
      iex>   end
      iex> rescue
      iex>   _ -> :failed
      iex> end
      :failed

  """
  @spec assert_async(Keyword.t(), Macro.expr()) :: true | no_return
  defmacro assert_async(opts \\ [], [do: expr] = expression) do
    sleep_time = Keyword.get(opts, :sleep_time, 10)
    timeout = Keyword.get(opts, :timeout, 100)

    assertion =
      assertion(
        quote do
          assert_async(unquote(opts), unquote(expression))
        end
      )

    condition =
      quote do
        fn -> unquote(expr) end
      end

    quote do
      assert_async(unquote(condition), unquote(assertion), unquote(timeout), unquote(sleep_time))
    end
  end

  @doc false
  def assert_async(condition, expr, timeout, sleep_time) do
    start_time = NaiveDateTime.utc_now()
    end_time = NaiveDateTime.add(start_time, timeout, :millisecond)
    assert_async(condition, end_time, expr, timeout, sleep_time)
  end

  @doc false
  def assert_async(condition, end_time, expr, timeout, sleep_time) do
    result =
      try do
        condition.()
      rescue
        _ in [ExUnit.AssertionError] -> false
      end

    if result == false do
      if NaiveDateTime.compare(NaiveDateTime.utc_now(), end_time) == :lt do
        Process.sleep(sleep_time)
        assert_async(condition, end_time, expr, timeout, sleep_time)
      else
        raise ExUnit.AssertionError,
          args: [timeout],
          expr: expr,
          message: "Given condition did not return true before timeout: #{timeout}"
      end
    else
      true
    end
  end

  defp assertion(quoted), do: Macro.escape(quoted, prune_metadata: true)

  defp stringify_list(list) do
    quote do
      unquote(list)
      |> Enum.map(fn
        elem when is_atom(elem) -> ":#{elem}"
        elem when is_binary(elem) -> "\"#{elem}\""
        elem -> "#{inspect(elem)}"
      end)
      |> Enum.join(", ")
    end
  end

  defp expand_pattern({:when, meta, [left, right]}, caller) do
    left = expand_pattern_except_vars(left, Macro.Env.to_match(caller))
    right = expand_pattern_except_vars(right, %{caller | context: :guard})
    {:when, meta, [left, right]}
  end

  defp expand_pattern(expr, caller) do
    expand_pattern_except_vars(expr, Macro.Env.to_match(caller))
  end

  defp expand_pattern_except_vars(expr, caller) do
    Macro.prewalk(expr, fn
      {var, _, context} = node when is_atom(var) and is_atom(context) -> node
      other -> Macro.expand(other, caller)
    end)
  end

  defp collect_vars_from_pattern(expr) do
    Macro.prewalk(expr, [], fn
      {:"::", _, [left, _]}, acc ->
        {[left], acc}

      {skip, _, [_]}, acc when skip in [:^, :@] ->
        {:ok, acc}

      {:_, _, context}, acc when is_atom(context) ->
        {:ok, acc}

      {name, meta, context}, acc when is_atom(name) and is_atom(context) ->
        {:ok, [{name, [generated: true] ++ meta, context} | acc]}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp collect_pins_from_pattern(expr, vars) do
    {_, pins} =
      Macro.prewalk(expr, [], fn
        {:^, _, [{name, _, nil} = var]}, acc ->
          if {name, nil} in vars do
            {:ok, [{name, var} | acc]}
          else
            {:ok, acc}
          end

        form, acc ->
          {form, acc}
      end)

    Enum.uniq_by(pins, &elem(&1, 0))
  end

  defp suppress_warning({name, meta, [expr, [do: clauses]]}) do
    clauses =
      Enum.map(clauses, fn {:->, meta, args} ->
        {:->, [generated: true] ++ meta, args}
      end)

    {name, meta, [expr, [do: clauses]]}
  end

  defp extract_args({root, meta, [_ | _] = args} = expr, env) do
    arity = length(args)

    reserved? =
      is_atom(root) and (Macro.special_form?(root, arity) or Macro.operator?(root, arity))

    all_quoted_literals? = Enum.all?(args, &Macro.quoted_literal?/1)

    case Macro.expand_once(expr, env) do
      ^expr when not reserved? and not all_quoted_literals? ->
        vars = for i <- 1..arity, do: Macro.var(:"arg#{i}", __MODULE__)

        quoted =
          quote do
            {unquote_splicing(vars)} = {unquote_splicing(args)}
            unquote({root, meta, vars})
          end

        {vars, quoted}

      other ->
        {ExUnit.AssertionError.no_value(), other}
    end
  end

  defp extract_args(expr, _env) do
    {ExUnit.AssertionError.no_value(), expr}
  end

  defp escape_quoted(kind, expr) do
    Macro.escape({kind, [], [expr]}, prune_metadata: true)
  end
end
