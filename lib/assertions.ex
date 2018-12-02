defmodule Assertions do
  @moduledoc """
  Helpful functions to help you write better tests.
  """

  @doc """
  Tests if two lists have the same elements without asserting they are in the
  same order.

  When you compare two lists for equality using `==`, order matters, which means
  `assert [1,2,3] == [1,3,2]` fails. However, for many situations, the order of
  elements in a list doesn't matter.

  If you only care that two lists have exactly the same elements, but not what
  order those elements are in, this is the assertion for you!

  ## Examples

      iex> lists_equal?([1,2,3], [1,3,2])
      true

      iex> lists_equal?([1,2,4], [1,3,2])
      false

      iex> lists_equal?([1,2,3,4], [1,3,2])
      false

      iex> lists_equal?([1,2,3], [1,3,2,4])
      false

  """
  def lists_equal?(left, right) do
    lists_equal?(left, right, &Kernel.==/2)
  end

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
    left_diff = compare(right, left, &Kernel.==/2)
    right_diff = compare(left, right, &Kernel.==/2)

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
      left_diff = Assertions.compare(right, left, comparison)
      right_diff = Assertions.compare(left, right, comparison)

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
      left_diff = Assertions.compare(right, left, comparison)
      right_diff = Assertions.compare(left, right, comparison)

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
  Tests if two lists have the same elements according to a given comparison
  function without asserting they are in the same order.

  This is very similar to `lists_equal?/2`, but it allows you to determine
  how two elements in your list are considered equal. This is especially helpful
  when comparing lists of structs, since comparing structs for equality with
  `==` is very error prone.

  The comparison function you pass as the third argument must be a function
  that takes two elements (one from the left list and one from the right list)
  and returns a boolean if those two elements are equal.

  ## Examples

      iex> lists_equal?([1,2,3], [1,3,2], &Kernel.==/2)
      true

      iex> lists_equal?(["12", "23.5"], ["23", "12 "], fn left, right ->
      ...>   {left_int, _} = Integer.parse(left)
      ...>   {right_int, _} = Integer.parse(right)
      ...>   left_int == right_int
      ...> end)
      true

      iex> left = [DateTime.utc_now(), Date.utc_today()]
      iex> right = [Date.utc_today(), DateTime.utc_now()]
      iex> lists_equal?(left, right, &structs_equal?(&1, &2, [:year, :month, :day]))
      true

      iex> left = [DateTime.utc_now()]
      iex> right = [Date.utc_today(), DateTime.utc_now()]
      iex> lists_equal?(left, right, &structs_equal?(&1, &2, [:year, :month, :day]))
      false

      iex> left = [Date.utc_today(), DateTime.utc_now()]
      iex> right = [DateTime.utc_now()]
      iex> lists_equal?(left, right, &structs_equal?(&1, &2, [:year, :month, :day]))
      false

  """
  def lists_equal?(left, right, comparison) do
    compare(left, right, comparison) == [] and compare(right, left, comparison) == []
  end

  def compare(left, right, comparison) do
    Enum.reduce(left, right, fn left_element, list ->
      case Enum.find_index(list, &comparison.(left_element, &1)) do
        nil -> list
        index -> List.delete_at(list, index)
      end
    end)
  end

  @doc """
  Tests if two structs have the same values at the given keys.

  Directly comparing structs for equality using `==` can be very tricky, which
  is why you almost never want to do that. Using this assertion, you get to
  determine what makes two structs equal while allowing for inconsequential
  differences.

  ## Examples

      iex> left = DateTime.utc_now()
      iex> right = Date.utc_today()
      iex> structs_equal?(left, right, [:year, :month, :day])
      true

      iex> left = DateTime.utc_now()
      iex> right = Date.utc_today()
      iex> structs_equal?(left, right, [:year, :month, :day, :second])
      false

  """
  def structs_equal?(left, right, keys) do
    map_values_equal?(left, right, keys, strict: true)
  end

  @doc """
  Tests if two maps have the same values at the given keys.

  ## Examples

      iex> left = %{first: :first, second: :second}
      iex> right = %{first: :first, second: :second, third: :third}
      iex> map_values_equal?(left, right, [:first, :second])
      true

      iex> left = %{first: "first", second: :second}
      iex> right = %{first: :first, second: :second, third: :third}
      iex> map_values_equal?(left, right, [:first, :second])
      false

      iex> left = %{first: :first, second: :second}
      iex> right = %{first: :first, third: :third}
      iex> map_values_equal?(left, right, [:first, :second])
      false

  By default if both maps are missing a given key, they are not considered
  equal.

      iex> left = %{first: :first, second: :second}
      iex> right = %{first: :first, second: :second, third: :third}
      iex> map_values_equal?(left, right, [:first, :second, "not_there"])
      false

  If you would like maps to be considered equal in this case, you can pass
  `strict: false` as the fourth argument.

      iex> left = %{first: :first, second: :second}
      iex> right = %{first: :first, second: :second, third: :third}
      iex> map_values_equal?(left, right, [:first, :second, "not_there"], strict: false)
      true

  """
  def map_values_equal?(left, right, keys, options \\ [strict: true]) do
    if options[:strict] do
      keys_present?(left, right, keys) and values_equal?(left, right, keys)
    else
      values_equal?(left, right, keys)
    end
  end

  defp keys_present?(left, right, keys) do
    left_keys = Map.keys(left)
    right_keys = Map.keys(right)
    Enum.all?(keys, fn key -> key in left_keys and key in right_keys end)
  end

  defp values_equal?(left, right, keys) do
    Enum.all?(keys, fn key -> value_for(left, key) == value_for(right, key) end)
  end

  defp value_for(struct, key) do
    Map.get(struct, key, {:error, :key_not_found_for_assertion})
  end

  @doc """
  Tests that a message matching the given pattern, and only that message, is
  received within the given time period, specified in milliseconds.

  The optional second argument is a timeout for the `receive` to wait for the
  expected message, and defaults to 100ms.

  If you want to check that no message was received before the expected message,
  **and** that no message is received for a given time after calling
  `receive_only?/2`, you can combine `received_only?/2` with
  `ExUnit.Assertions.refute_receive/3`.

      assert receive_only?(:hello)
      refute_receive _, 100

  ## Examples

      iex> send(self(), :hello)
      iex> receive_only?(:hello)
      true

      iex> send(self(), [:hello])
      iex> receive_only?([_])
      true

      iex> a = :hello
      iex> send(self(), :hello)
      iex> receive_only?(^a)
      true

      iex> send(self(), :hello)
      iex> send(self(), :hello_again)
      iex> receive_only?(:hello)
      false

  If a message is received after the function has matched a message to the given
  pattern, but the second message is received before the timeout, that second
  message is ignored and the function returns `true`.

  This function only tests that the message that matches the given pattern was
  the first message in the process inbox, and that nothing was sent between the
  sending the message that matches the pattern and when `receive_only?/2` was
  called.

      iex> Process.send_after(self(), :hello, 20)
      iex> Process.send_after(self(), :hello_again, 50)
      iex> receive_only?(:hello, 100)
      true

      iex> Process.send_after(self(), :hello, 50)
      iex> Process.send_after(self(), :hello_again, 20)
      iex> receive_only?(:hello, 100)
      false

  """
  defmacro receive_only?(expected_pattern, timeout \\ 100) do
    pattern = Macro.expand(expected_pattern, __CALLER__)

    quote do
      receive do
        unquote(pattern) ->
          receive do
            _ -> false
          after
            0 -> true
          end
      after
        unquote(timeout) -> false
      end
    end
  end

  @doc """
  Tests that messages matching the given patterns, and only those messages, are
  received in order within the given time period, specified in milliseconds.

  This is an expansion of `receive_only?/2`. See the documentation there for
  details on the behavior of this function.

  ## Examples

      iex> send(self(), :hello)
      iex> send(self(), :hello_again)
      iex> send(self(), :goodbye)
      iex> receive_exactly?([:hello, :hello_again, :goodbye])
      true

      iex> send(self(), :hello)
      iex> Process.send_after(self(), :hello_again, 50)
      iex> receive_exactly?([:hello, :hello_again])
      true

      iex> send(self(), :hello_again)
      iex> send(self(), :hello)
      iex> receive_exactly?([:hello, :hello_again])
      false

      iex> send(self(), :hello)
      iex> send(self(), :goodbye)
      iex> send(self(), :hello_again)
      iex> receive_exactly?([:hello, :hello_again])
      false

      iex> send(self(), :hello)
      iex> send(self(), :hello_again)
      iex> send(self(), :goodbye)
      iex> receive_exactly?([:hello, :hello_again])
      false

      iex> send(self(), :goodbye)
      iex> send(self(), :hello)
      iex> send(self(), :hello_again)
      iex> receive_exactly?([:hello, :hello_again])
      false

      iex> hello = :hello
      iex> send(self(), hello)
      iex> send(self(), :hello_again)
      iex> receive_exactly?([^hello, :hello_again])
      true

      iex> hello = :hello
      iex> send(self(), :hello_again)
      iex> send(self(), hello)
      iex> receive_exactly?([^hello, _])
      false

  """

  defmacro receive_exactly?(expected_patterns, timeout \\ 100) do
    caller = __CALLER__
    [pattern | rest] = Enum.map(expected_patterns, &Macro.expand(&1, caller))

    quote do
      receive do
        matched ->
          if match?(unquote(pattern), matched) do
            unquote(wait_for_pattern(rest))
          else
            false
          end
      after
        unquote(timeout) -> false
      end
    end
  end

  defp wait_for_pattern([]) do
    quote do
      receive do
        _ -> false
      after
        0 -> true
      end
    end
  end

  defp wait_for_pattern([{ignored, _, nil} | rest]) when is_atom(ignored) do
    quote do
      receive do
        _ ->
          unquote(wait_for_pattern(rest))
      end
    end
  end

  defp wait_for_pattern([pattern | rest]) do
    quote do
      receive do
        matched ->
          if match?(unquote(pattern), matched) do
            unquote(wait_for_pattern(rest))
          else
            false
          end
      end
    end
  end
end
