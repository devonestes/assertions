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
end
