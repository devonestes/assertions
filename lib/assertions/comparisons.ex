defmodule Assertions.Comparisons do
  @moduledoc false

  @doc false
  def compare_maps(left, right, comparison \\ &Kernel.==/2) do
    {left_diff, right_diff, equal?} =
      compare_lists(Map.to_list(left), Map.to_list(right), comparison)

    {Map.new(left_diff), Map.new(right_diff), equal?}
  end

  @doc false
  def compare_lists(left, right, comparison \\ &Kernel.==/2) do
    left_diff = compare(right, left, comparison)
    right_diff = compare(left, right, comparison)
    {left_diff, right_diff, left_diff == right_diff}
  end

  defp compare(left, right, comparison) do
    Enum.reduce(left, right, fn left_element, list ->
      case Enum.find_index(list, &comparison.(left_element, &1)) do
        nil -> list
        index -> List.delete_at(list, index)
      end
    end)
  end
end
