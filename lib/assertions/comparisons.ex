defmodule Assertions.Comparisons do
  @moduledoc false

  @doc false
  def compare_maps(left, right, comparison \\ &Kernel.==/2) when is_map(left) and is_map(right) do
    {left_diff, right_diff, equal?} =
      compare_lists(Map.to_list(left), Map.to_list(right), comparison)

    {Map.new(left_diff), Map.new(right_diff), equal?}
  end

  @doc false
  def compare_lists(left, right, comparison \\ &Kernel.==/2)
      when is_list(left) and is_list(right) do
    {left_diff, right_diff} =
      Enum.reduce(1..length(left), {left, right}, &compare(&1, &2, comparison))

    {left_diff, right_diff, left_diff == [] and right_diff == []}
  end

  @doc false
  def when_is_list(arg, positive, negative) do
    if is_list(arg) do
      positive.(arg)
    else
      negative.(arg)
    end
  end

  defp compare(_, {[left_elem | left_acc], right_acc}, comparison) do
    result =
      Enum.find_index(right_acc, fn right_elem ->
        try do
          comparison.(left_elem, right_elem)
        rescue
          _ in [ExUnit.AssertionError] -> false
        end
      end)

    case result do
      nil -> {left_acc ++ [left_elem], right_acc}
      index -> {left_acc, List.delete_at(right_acc, index)}
    end
  end

  defp compare(_, acc, _), do: acc
end
