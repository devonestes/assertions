defmodule Assertions do
  @moduledoc """
  Helpful functions to help you write better tests.
  """

  alias Assertions.Predicates

  @type comparison :: (any, any -> boolean)

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
      {left_diff, right_diff, equal?} = compare_lists(unquote(left), unquote(right), &Kernel.==/2)

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right)],
          left_diff,
          right_diff,
          unquote(assertion),
          "Comparison of each element failed!"
        )
      end
    end
  end

  @doc """
  Asserts that two lists contain the same elements without asserting they are
  in the same order.

  The third argument can either be a custom failure message, or a function used
  to compare elements in the lists.

      iex> assert_lists_equal([1, 2, 3], [1, 3, 2], "NOT A MATCH")
      true

      iex> assert_lists_equal(["dog"], ["cat"], &(String.length(&1) == String.length(&2)))
      true

  """
  @spec assert_lists_equal(list, list, comparison | String.t()) :: true | no_return
  defmacro assert_lists_equal(left, right, message_or_comparison)

  defmacro assert_lists_equal(left, right, message) when is_binary(message) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right), unquote(message))
        end
      )

    quote do
      {left_diff, right_diff, equal?} = compare_lists(unquote(left), unquote(right), &Kernel.==/2)

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right), unquote(message)],
          left_diff,
          right_diff,
          unquote(assertion),
          unquote(message)
        )
      end
    end
  end

  defmacro assert_lists_equal(left, right, comparison) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right), unquote(comparison))
        end
      )

    quote do
      {left_diff, right_diff, equal?} =
        compare_lists(unquote(left), unquote(right), unquote(comparison))

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right), unquote(comparison)],
          left_diff,
          right_diff,
          unquote(assertion),
          "Comparison of each element failed!"
        )
      end
    end
  end

  @doc """
  Asserts that two lists contain the same elements without asserting they are
  in the same order.

  If the comparison fails, the given `message` is used as the failure message.

      iex> assert_lists_equal(
      iex>   ["dog"],
      iex>   ["cat"],
      iex>   &(String.length(&1) == String.length(&2)),
      iex>   "FAILED WITH CUSTOM MESSAGE"
      iex> )
      true

  """
  @spec assert_lists_equal(list, list, comparison, String.t()) :: true | no_return
  defmacro assert_lists_equal(left, right, comparison, message) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right), unquote(comparison), unquote(message))
        end
      )

    quote do
      {left_diff, right_diff, equal?} =
        compare_lists(unquote(left), unquote(right), unquote(comparison))

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right), unquote(comparison), unquote(message)],
          left_diff,
          right_diff,
          unquote(assertion),
          unquote(message)
        )
      end
    end
  end

  @doc """
  Asserts that a `map` with the same values for the given `keys` is in the
  `list`.

      iex> list = [%{first: :first, second: :second, third: :third}]
      iex> assert_map_in_list(%{first: :first, second: :second}, list, [:first, :second])
      true

  """
  @spec assert_map_in_list(map, [map], [any]) :: true | no_return
  defmacro assert_map_in_list(map, list, keys) do
    assertion =
      assertion(
        quote do
          assert_map_in_list(unquote(map), unquote(list), unquote(keys))
        end
      )

    quote do
      keys = unquote(keys)
      list = Enum.map(unquote(list), &Map.take(&1, keys))
      map = Map.take(unquote(map), keys)

      unless Predicates.map_in_list?(map, list, keys) do
        raise ExUnit.AssertionError,
          args: [unquote(map), unquote(list)],
          left: map,
          right: list,
          expr: unquote(assertion),
          message: "Map matching the values for keys `#{unquote(stringify_list(keys))}` not found"
      else
        true
      end
    end
  end

  @doc """
  Asserts that the values in `left` and `right` are the same for the `keys`

      iex> left = %{first: :first, second: :second, third: :third}
      iex> right = %{first: :first, second: :second, third: :fourth}
      iex> assert_maps_equal(left, right, [:first, :second])
      true

  """
  @spec assert_maps_equal(map, map, [any]) :: true | no_return
  defmacro assert_maps_equal(left, right, keys) do
    assertion =
      assertion(
        quote do
          assert_maps_equal(unquote(left), unquote(right), unquote(keys))
        end
      )

    quote do
      keys = unquote(keys)
      left = Map.take(unquote(left), keys)
      right = Map.take(unquote(right), keys)
      {left_diff, right_diff, equal?} = compare_maps(left, right)

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right)],
          left_diff,
          right_diff,
          unquote(assertion),
          "Values for #{unquote(stringify_list(keys))} not equal!"
        )
      end
    end
  end

  @doc """
  Asserts that a struct with certain values is present in the `list`.

  There are two ways to make this comparison.

  First is to pass a struct, a list of keys to use to compare that struct to
  the structs in the list, and a list of structs.

      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> assert_struct_in_list(DateTime.utc_now(), [:year, :month, :day, :second], list)
      true

  The second way to use this assertion is to pass a map of keys and values that
  you expect to be in the struct, a module representing the type of struct you
  are expecting, and a list of structs.

      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> year = DateTime.utc_now().year
      iex> assert_struct_in_list(%{year: year}, DateTime, list)
      true

  """
  @spec assert_struct_in_list(struct, [any], [struct]) :: true | no_return
  @spec assert_struct_in_list(map, module, [struct]) :: true | no_return
  defmacro assert_struct_in_list(struct_or_map, keys_or_type, list)

  defmacro assert_struct_in_list(struct, keys, list) when is_list(keys) do
    assertion =
      assertion(
        quote do
          assert_struct_in_list(unquote(struct), unquote(keys), unquote(list))
        end
      )

    quote do
      keys = [:__struct__ | unquote(keys)]
      struct = Map.take(unquote(struct), keys)
      list = Enum.map(unquote(list), fn map -> Map.take(map, keys) end)

      if Predicates.struct_in_list?(struct, list, keys) do
        true
      else
        raise(
          [unquote(struct), unquote(keys), unquote(list)],
          struct,
          list,
          unquote(assertion),
          "Struct matching the values for keys #{unquote(stringify_list(keys))} not found"
        )
      end
    end
  end

  defmacro assert_struct_in_list(map, module, list) do
    assertion =
      assertion(
        quote do
          assert_struct_in_list(unquote(map), unquote(module), unquote(list))
        end
      )

    quote do
      map = Map.put(unquote(map), :__struct__, unquote(module))
      keys = Map.keys(map)
      list = Enum.map(unquote(list), fn map -> Map.take(map, keys) end)

      if map in list do
        true
      else
        raise(
          [unquote(map), unquote(module), unquote(list)],
          map,
          list,
          unquote(assertion),
          "Struct matching #{inspect(map)} not found"
        )
      end
    end
  end

  @doc """
  Asserts that the values in struct `left` and struct `right` are the same for
  the given `keys`

      iex> assert_structs_equal(DateTime.utc_now(), DateTime.utc_now(), [:year, :minute])
      true

  """
  @spec assert_structs_equal(struct, struct, [any]) :: true | no_return
  defmacro assert_structs_equal(left, right, keys) do
    assertion =
      assertion(
        quote do
          assert_structs_equal(unquote(left), unquote(right), unquote(keys))
        end
      )

    quote do
      keys = [:__struct__ | unquote(keys)]
      left = Map.take(unquote(left), keys)
      right = Map.take(unquote(right), keys)

      {left_diff, right_diff, equal?} = compare_maps(left, right)

      if equal? do
        true
      else
        raise(
          [unquote(left), unquote(right)],
          left_diff,
          right_diff,
          unquote(assertion),
          "Values for #{unquote(stringify_list(keys))} not equal!"
        )
      end
    end
  end

  @doc """
  Asserts that the value for all maps, structs or keyword lists in `list` have
  the same `value` for `key`.

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
        raise(
          [unquote(list), unquote(key), unquote(value)],
          %{key => value},
          diff,
          unquote(assertion),
          "Values for `#{inspect(key)}` not equal in all elements!"
        )
      end
    end
  end

  @doc """
  Asserts that the file at `path` is changed to match `comparison` after
  executing `expr`.

  If the file matches `comparison` before executing `expr`, this assertion will
  fail. The file does not have to exist before executing `expr` in order for
  this assertion to pass.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> File.mkdir_p!(Path.dirname(path))
      iex> result = assert_changes_file(path, "hi", File.write(path, "hi"))
      iex> File.rm_rf!(Path.dirname(path))
      iex> result
      true

  """
  @spec assert_changes_file(Path.t(), String.t() | Regex.t(), Macro.expr()) :: true | no_return
  defmacro assert_changes_file(path, comparison, expr) do
    assertion =
      assertion(
        quote do
          assert_changes_file(unquote(path), unquote(comparison), unquote(expr))
        end
      )

    quote do
      path = unquote(path)
      comparison = unquote(comparison)
      args = [unquote(path), unquote(comparison), unquote(Macro.to_string(expr))]

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
          raise(
            args,
            end_file,
            comparison,
            unquote(assertion),
            "File did not change to match comparison after expr!"
          )
        end
      end
    end
  end

  @doc """
  Asserts that the file at `path` is created after executing `expr`.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> File.mkdir_p!(Path.dirname(path))
      iex> result = assert_creates_file(path, File.write(path, "hi"))
      iex> File.rm_rf!(Path.dirname(path))
      iex> result
      true

  """
  @spec assert_creates_file(Path.t(), Macro.expr()) :: true | no_return
  defmacro assert_creates_file(path, expr) do
    assertion =
      assertion(
        quote do
          assert_creates_file(unquote(path), unquote(expr))
        end
      )

    quote do
      path = unquote(path)
      args = [unquote(path), unquote(Macro.to_string(expr))]

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
  Asserts that the file at `path` is deleted after executing `expr`.

      iex> path = Path.expand("../tmp/file.txt", __DIR__)
      iex> File.mkdir_p!(Path.dirname(path))
      iex> File.write(path, "hi")
      iex> assert_deletes_file(path, File.rm_rf!(Path.dirname(path)))
      true

  """
  @spec assert_deletes_file(Path.t(), Macro.expr()) :: true | no_return
  defmacro assert_deletes_file(path, expr) do
    assertion =
      assertion(
        quote do
          assert_deletes_file(unquote(path), unquote(expr))
        end
      )

    quote do
      path = unquote(path)
      args = [unquote(path), unquote(Macro.to_string(expr))]

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

  # defmacro assert_receive_exactly(expected_patterns, timeout \\ 100) do
  # end

  # defmacro assert_receive_only(expected_pattern, timeout \\ 100) do
  # end

  @doc false
  def compare_maps(left, right) do
    {left_diff, right_diff, equal?} =
      compare_lists(Map.to_list(left), Map.to_list(right), &Kernel.==/2)

    {Map.new(left_diff), Map.new(right_diff), equal?}
  end

  @doc false
  def compare_lists(left, right, comparison)
      when is_function(comparison, 2) and is_list(left) and is_list(right) do
    left_diff = Predicates.compare(right, left, comparison)
    right_diff = Predicates.compare(left, right, comparison)
    {left_diff, right_diff, left_diff == right_diff}
  end

  def compare_lists(left, right, comparison) do
    quote do
      left = unquote(left)
      right = unquote(right)
      comparison = unquote(comparison)
      left_diff = Predicates.compare(right, left, comparison)
      right_diff = Predicates.compare(left, right, comparison)
      {left_diff, right_diff, left_diff == right_diff}
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

  # public because we're calling it from inside a macro
  @doc false
  def raise(args, left, right, expr, message) do
    raise ExUnit.AssertionError,
      args: args,
      left: left,
      right: right,
      expr: expr,
      message: message
  end
end
