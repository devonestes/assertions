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
      iex>     assert error.message == "Comparison of each element with `==` failed!"
      iex> end
      true

  """
  defmacro assert_lists_equal(left, right) do
    quote do
      assert_lists_equal(
        unquote(left),
        unquote(right),
        "Comparison of each element with `==` failed!"
      )
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
    left_diff = Predicates.compare(right, left, &Kernel.==/2)
    right_diff = Predicates.compare(left, right, &Kernel.==/2)

    expr =
      quote do
        left_diff == right_diff
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

    # This can only happen if both are empty lists
    unless left_diff == right_diff do
      quote do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: unquote(left_diff),
          right: unquote(right_diff),
          expr: unquote(assertion),
          message: unquote(message)
      end
    else
      true
    end
  end

  defmacro assert_lists_equal(left, right, comparison) do
    expr =
      quote do
        left_diff == right_diff
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

    quote do
      comparison = unquote(comparison)
      left = unquote(left)
      right = unquote(right)
      left_diff = Predicates.compare(right, left, comparison)
      right_diff = Predicates.compare(left, right, comparison)

      unless left_diff == right_diff do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
          left: left_diff,
          right: right_diff,
          expr: unquote(assertion),
          message: "Comparison of each element with `#{inspect(unquote(comparison))}` failed!"
      else
        true
      end
    end
  end

  defmacro assert_lists_equal(left, right, comparison, message) do
    expr =
      quote do
        left_diff == right_diff
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

    quote do
      comparison = unquote(comparison)
      left = unquote(left)
      right = unquote(right)
      left_diff = Predicates.compare(right, left, comparison)
      right_diff = Predicates.compare(left, right, comparison)

      unless left_diff == right_diff do
        raise ExUnit.AssertionError,
          args: [unquote(left), unquote(right)],
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
        map in list
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

    quote do
      list =
        Enum.map(unquote(list), fn map ->
          Map.take(map, unquote(keys))
        end)

      unless Predicates.map_in_list?(unquote(map), list, unquote(keys)) do
        raise ExUnit.AssertionError,
          args: [unquote(map), list],
          left: unquote(map),
          right: list,
          expr: unquote(assertion),
          message: "Map matching the values for keys #{unquote(inspect(keys))} not found"
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
        nil
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

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
        struct in list
      end

    assertion = Macro.escape({:assert, [], [expr]}, prune_metadata: true)

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
        nil
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
