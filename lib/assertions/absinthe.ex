defmodule Assertions.Absinthe do
  # We need to unwrap non_null and list types
  def fields_for(schema, %{of_type: type}, nesting) do
    fields_for(schema, type, nesting)
  end

  def fields_for(schema, type, nesting) do
    type
    |> schema.__absinthe_type__()
    |> get_fields(schema, nesting)
  end

  # We don't include any other objects in the list when we've reached the end of our nesting,
  # otherwise the resulting document would be invalid because we need to select sub-fields of
  # all objects.
  defp get_fields(%{fields: _}, _, 0) do
    :reject
  end

  defp get_fields(%{fields: fields} = type, schema, nesting) do
    Enum.reduce(fields, [], fn {key, value}, acc ->
      case fields_for(schema, value.type, nesting - 1) do
        nil -> [key | acc]
        :reject -> acc
        list -> [{key, list} | acc]
      end
    end)
  end

  # This catches scalar types which have no sub fields
  defp get_fields(_, _, _) do
    nil
  end
end
