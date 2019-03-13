defmodule Assertions.Comparisons do
  @moduledoc """
  Helpful functions to use as comparison functions when composed with
  assertions. These functions will all provide diffs to aid in shrinking the
  diffs shown in the error messages.
  """
  @spec maps_equal?(map, map) :: {map, map, boolean}
  def maps_equal?(left, right) do
    comparison = fn left, right ->
      Enum.into(Map.to_list(left) -- Map.to_list(right), %{})
    end

    maps_equal?(left, right, comparison)
  end

  @doc """
  Determines if map `left` is equal to map `right` based on the values at a
  given set of keys or the return of a given comparison function.

  The comparison should return the diff between the first and second arguments
  to the function - in this case a map that only contains key/value pairs that
  do not have an equal key/value pair in the second argument. This returning of
  the diff between the two arguments is what powers the shrinking of diffs in
  the error messages.
  """
  @spec maps_equal?(map, map, list | (map, map -> map)) :: {map, map, boolean}
  def maps_equal?(left, right, keys) when is_list(keys) do
    if Keyword.keyword?(keys) do
      to_take = Keyword.keys(keys)
      left = Map.take(left, to_take)
      right = Map.take(right, to_take)

      comparison = fn left, right ->
        Enum.reduce(keys, %{}, fn
          {key, nil}, acc ->
            if Map.get(left, key, :not_found_for_comparison) == Map.get(right, key) do
              acc
            else
              if Map.has_key?(left, key) do
                Map.put(acc, key, Map.get(left, key))
              else
                acc
              end
            end

          {key, function}, acc ->
            case function.(Map.get(left, key), Map.get(right, key)) do
              false -> Map.put(acc, key, Map.get(left, key))
              {left_diff, _, false} -> Map.put(acc, key, left_diff)
              diff when map_size(diff) > 0 -> Map.put(acc, key, diff)
              _ -> acc
            end
        end)
      end

      maps_equal?(left, right, comparison)
    else
      comparison = fn left, right ->
        Enum.reduce(keys, %{}, fn
          {key, function}, acc when is_function(function) ->
            if Map.has_key?(left, key) do
              if function.(Map.get(left, key), Map.get(right, key, :not_found)) do
                acc
              else
                Map.put(acc, key, Map.get(left, key))
              end
            else
              acc
            end

          {key, keys}, acc when is_list(keys) ->
            case maps_equal?(Map.get(left, key), Map.get(right, key), keys) do
              {left, _, false} -> Map.put(acc, key, left)
              _ -> acc
            end

          key, acc ->
            if Map.has_key?(left, key) do
              if Map.get(left, key) == Map.get(right, key, :not_found) do
                acc
              else
                Map.put(acc, key, Map.get(left, key))
              end
            else
              acc
            end
        end)

        # {key, nil}, acc ->
        # if Map.get(left, key, :not_found_for_comparison) == Map.get(right, key) do
        # acc
        # else
        # if Map.has_key?(left, key) do
        # Map.put(acc, key, Map.get(left, key))
        # else
        # acc
        # end
        # end

        # {key, function}, acc ->
        # case function.(Map.get(left, key), Map.get(right, key)) do
        # false -> Map.put(acc, key, Map.get(left, key))
        # {left_diff, _, false} -> Map.put(acc, key, left_diff)
        # diff when map_size(diff) > 0 -> Map.put(acc, key, diff)
        # _ -> acc
        # end
      end

      maps_equal?(left, right, comparison)
    end
  end

  def maps_equal?(left, right, comparison) when is_function(comparison, 2) do
    left_diff = comparison.(left, right)
    right_diff = comparison.(right, left)
    {left_diff, right_diff, left_diff == %{} and right_diff == %{}}
  end

  @doc false
  def compare_maps(left, right, comparison \\ &Kernel.==/2) when is_map(left) and is_map(right) do
    {left_diff, right_diff, equal?, _} =
      compare_lists(Map.to_list(left), Map.to_list(right), comparison)

    {Map.new(left_diff), Map.new(right_diff), equal?}
  end

  @doc false
  def compare_lists(left, right, comparison \\ &Kernel.==/2, check_return_values \\ false)
      when is_list(left) and is_list(right) do
    {left_diff, invalid_return1} = compare(right, left, comparison, check_return_values)
    {right_diff, invalid_return2} = compare(left, right, comparison, check_return_values)
    {left_diff, right_diff, left_diff == right_diff, invalid_return1 or invalid_return2}
  end

  defp compare(left, right, comparison, false) do
    diff =
      Enum.reduce(left, right, fn left_element, list ->
        case Enum.find_index(list, &comparison.(left_element, &1)) do
          nil -> list
          index -> List.delete_at(list, index)
        end
      end)

    {diff, false}
  end

  defp compare(left, right, comparison, true) do
    diff =
      Enum.reduce(left, right, fn left_element, list ->
        case Enum.find_index(list, &comparison.(left_element, &1)) do
          nil -> list
          index -> List.delete_at(list, index)
        end
      end)

    invalid_return =
      Enum.all?(left, fn left_element ->
        Enum.all?(right, &is_boolean(comparison.(&1, left_element)))
      end)

    {diff, !invalid_return}
  end
end
