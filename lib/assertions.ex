defmodule Assertions do
  @moduledoc """
  Helpful functions to help you write better tests.
  """

  alias Assertions.Predicates

  @doc """
  Asserts that two lists are equal without asserting they are in the same order.

      iex> assert_lists_equal([1,2,3], [1,3,2])
      true

      iex> try do
      iex>   assert_lists_equal([1,2,4], [1,3,2])
      iex> rescue
      iex>   error in [ExUnit.AssertionError] ->
      iex>     assert error.message == "Comparison of each element failed!"
      iex> end
      true

  """
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
  Asserts that two lists are equal without asserting they are in the same order,
  and outputs the given failure message.

      iex> assert_lists_equal([1,2,3], [1,3,2])
      true

  If you want, you can provide a custom failure message.

      iex> try do
      iex>   assert_lists_equal([1,2,4], [1,3,2], "NOT A MATCH")
      iex> rescue
      iex>   error in [ExUnit.AssertionError] ->
      iex>     assert error.message == "NOT A MATCH"
      iex> end
      true

  You can also provide a custom function to use to compare your elements in your
  lists.

      iex> assert_lists_equal(["dog"], ["cat"], &(String.length(&1) == String.length(&2)))
      true

  You can also provide a custom failure message as well as a custom function to
  use to compare elements in your lists.

      iex> try do
      iex>   assert_lists_equal(["dog"], ["lion"], &(String.length(&1) == String.length(&2)), "FAILED WITH CUSTOM MESSAGE")
      iex> rescue
      iex>   error in [ExUnit.AssertionError] ->
      iex>     assert error.message == "FAILED WITH CUSTOM MESSAGE"
      iex> end
      true

  """
  defmacro assert_lists_equal(left, right, message) when is_binary(message) do
    assertion =
      assertion(
        quote do
          assert_lists_equal(unquote(left), unquote(right), unquote(message))
        end
      )

    {left_diff, right_diff, equal?} = compare_lists(left, right, &Kernel.==/2)

    if equal? do
      true
    else
      quote do
        raise(
          [unquote(left), unquote(right), unquote(message)],
          unquote(left_diff),
          unquote(right_diff),
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

    result = compare_lists(left, right, comparison)

    quote do
      {left_diff, right_diff, equal?} = unquote(result)

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

    # quote do
    # comparison = unquote(comparison)
    # left = unquote(left)
    # right = unquote(right)
    # left_diff = Predicates.compare(right, left, comparison)
    # right_diff = Predicates.compare(left, right, comparison)

    # if left_diff == right_diff do
    # true
    # else
    # raise ExUnit.AssertionError,
    # args: [left, right, comparison],
    # left: left_diff,
    # right: right_diff,
    # expr: unquote(assertion),
    # message: "Comparison of each element failed!"
    # end
    # end
  end

  defmacro assert_lists_equal(left, right, comparison, message) do
    expr =
      quote do
        assert_lists_equal(unquote(left), unquote(right), unquote(comparison), unquote(message))
      end

    assertion = Macro.escape(expr, prune_metadata: true)

    quote do
      comparison = unquote(comparison)
      left = unquote(left)
      right = unquote(right)
      left_diff = Predicates.compare(right, left, comparison)
      right_diff = Predicates.compare(left, right, comparison)

      unless left_diff == right_diff do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right), unquote(comparison), unquote(message)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: unquote(message)
      else
        true
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
  defmacro assert_map_in_list(map, list, keys) do
    expr =
      quote do
        assert_map_in_list(map, list, keys)
      end

    assertion = Macro.escape(expr, prune_metadata: true)

    quote do
      keys = unquote(keys)
      keys_for_message = unquote(stringify_list(keys))

      list =
        Enum.map(unquote(list), fn map ->
          Map.take(map, unquote(keys))
        end)

      map = Map.take(unquote(map), unquote(keys))

      unless Predicates.map_in_list?(unquote(map), list, unquote(keys)) do
        raise ExUnit.AssertionError,
          args: [unquote(map), unquote(list)],
          left: map,
          right: list,
          expr: unquote(assertion),
          message: "Map matching the values for keys `#{keys_for_message}` not found"
      else
        true
      end
    end
  end

  @doc """
  Asserts that the values in map `left` and map `right` are the same for the
  given `keys`

      iex> left = %{first: :first, second: :second, third: :third}
      iex> right = %{first: :first, second: :second, third: :fourth}
      iex> assert_maps_equal(left, right, [:first, :second])
      true

  """
  defmacro assert_maps_equal(left, right, keys) do
    expr =
      quote do
        assert_maps_equal(left, right, keys)
      end

    assertion = Macro.escape(expr, prune_metadata: true)

    quote do
      left_diff =
        unquote(left)
        |> Map.take(unquote(keys))
        |> Enum.reject(fn {k, v} -> Map.get(unquote(right), k, :not_found) == v end)
        |> Map.new()

      right_diff =
        unquote(right)
        |> Map.take(unquote(keys))
        |> Enum.reject(fn {k, v} -> Map.get(unquote(left), k, :not_found) == v end)
        |> Map.new()

      unless left_diff == %{} and right_diff == %{} do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: "Values for #{inspect(unquote(keys))} not equal!"
      else
        true
      end
    end
  end

  @doc """
  Asserts that a `struct` with the same values for the given `keys` is in the
  `list`.

      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> assert_struct_in_list(DateTime.utc_now(), list, [:year, :month, :day, :second])
      true

  """
  defmacro assert_struct_in_list(struct, list, keys) do
    expr =
      quote do
        assert_struct_in_list(struct, list, keys)
      end

    assertion = Macro.escape(expr, prune_metadata: true)

    quote do
      list =
        Enum.map(unquote(list), fn map ->
          Map.take(map, unquote(keys))
        end)

      unless Predicates.struct_in_list?(unquote(struct), unquote(list), unquote(keys)) do
        raise ExUnit.AssertionError,
          args: [unquote(struct), unquote(list)],
          left: Map.take(unquote(struct), unquote(keys)),
          right: list,
          expr: unquote(assertion),
          message: "Struct matching the values for keys #{unquote(inspect(keys))} not found"
      else
        true
      end
    end
  end

  @doc """
  Asserts that the values in map `left` and map `right` are the same for the
  given `keys`

      iex> assert_structs_equal(DateTime.utc_now(), DateTime.utc_now(), [:year, :minute])
      true

  """
  defmacro assert_structs_equal(left, right, keys) do
    expr =
      quote do
        assert_structs_equal(left, right, keys)
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

    quote do
      keys = [:__struct__ | unquote(keys)]

      left_diff =
        unquote(left)
        |> Map.take(unquote(keys))
        |> Enum.reject(fn {k, v} -> Map.get(unquote(right), k, :not_found) == v end)
        |> Map.new()

      right_diff =
        unquote(right)
        |> Map.take(unquote(keys))
        |> Enum.reject(fn {k, v} -> Map.get(unquote(left), k, :not_found) == v end)
        |> Map.new()

      unless left_diff == %{} and right_diff == %{} and
               unquote(left).__struct__ == unquote(right).__struct__ do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: "Values for #{inspect(Map.keys(left_diff))} not equal!"
      else
        true
      end
    end
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

  defp assertion(quoted) do
    Macro.escape(quoted, prune_metadata: true)
  end

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

  # defmacro assert_all_have_value(list, key, value) do
  # end

  # defmacro assert_changes_file(path, comparison, do: block) do
  # end

  # defmacro assert_creates_file(path, do: block) do
  # end

  # defmacro assert_deletes_file(path, do: block) do
  # end

  # defmacro assert_receive_exactly(expected_patterns, timeout \\ 100) do
  # end

  # defmacro assert_receive_only(expected_pattern, timeout \\ 100) do
  # end
end
