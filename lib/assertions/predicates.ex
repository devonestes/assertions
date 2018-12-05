defmodule Assertions.Predicates do
  @moduledoc """
  All of the predicate functions which return boolean values.
  """

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

  # Public for now because I'm using it in a kind of complicated macro.
  # It would be great to make this private again later on.
  @doc false
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
  differences like relations that are preloaded in one struct but not in the
  other.

  If you are comparing a struct to a map with the same keys and values, the
  check will fail. Both structs need to be of the same type for the check to
  pass.

  ## Examples

      iex> left = DateTime.utc_now()
      iex> right = DateTime.utc_now()
      iex> structs_equal?(left, right, [:year, :month, :day])
      true

      iex> left = DateTime.utc_now()
      iex> right = Date.utc_today()
      iex> structs_equal?(left, right, [:year, :month, :day])
      false

      iex> left = DateTime.utc_now()
      iex> right = Map.from_struct(DateTime.utc_now())
      iex> structs_equal?(left, right, [:year, :month, :day])
      false

  """
  def structs_equal?(left, right, keys) do
    keys = [:__struct__ | keys]
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

  defp value_for(map, key) do
    Map.get(map, key, {:error, :key_not_found_for_assertion})
  end

  #defmacro changes_file?(path, comparison, do: block) do
  #end

  #defmacro creates_file?(path, do: block) do
  #end

  #defmacro deletes_file?(path, do: block) do
  #end

  @doc """
  Tests if `struct` is in the given `list` by checking the values of the given
  `keys`.

    ## Examples

      iex> list = [DateTime.utc_now(), Date.utc_today()]
      iex> assert struct_in_list?(DateTime.utc_now(), list, [:year, :month, :day, :second])
      true

  """
  def struct_in_list?(struct, list, keys) do
    keys = [:__struct__ | keys]
    map_in_list?(struct, list, keys)
  end

  def map_in_list?(map, list, keys) do
    map_keys = Map.keys(map)

    Enum.all?(keys, &(&1 in map_keys)) and Enum.any?(list, &values_equal?(&1, map, keys))
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
