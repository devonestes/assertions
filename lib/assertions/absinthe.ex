defmodule Assertions.Absinthe do
  # We need to unwrap non_null and list sub-fields
  def fields_for(schema, %{of_type: type}, nesting) do
    fields_for(schema, type, nesting)
  end

  def fields_for(schema, type, nesting) do
    type
    |> schema.__absinthe_type__()
    |> get_fields(schema, nesting)
  end

  def document_for(schema, type, nesting) do
    schema
    |> fields_for(type, nesting)
    |> format_fields(type, 0)
    |> List.to_string()
  end

  # We don't include any other objects in the list when we've reached the end of our nesting,
  # otherwise the resulting document would be invalid because we need to select sub-fields of
  # all objects.
  defp get_fields(%{fields: _}, _, 0) do
    :reject
  end

  defp get_fields(%{fields: fields}, schema, nesting) do
    Enum.reduce(fields, [], fn {_, value}, acc ->
      case fields_for(schema, value.type, nesting - 1) do
        :reject -> acc
        :scalar -> [String.to_atom(value.name) | acc]
        list -> [{String.to_atom(value.name), list} | acc]
      end
    end)
  end

  defp get_fields(_, _, _) do
    :scalar
  end

  defp format_fields(fields, type, left_pad) do
    fields =
      fields
      |> Enum.reduce({["#{camelize(type)} {\n"], left_pad + 2}, &do_format_fields/2)
      |> elem(0)

    Enum.reverse(["}\n", padding(left_pad) | fields])
  end

  defp do_format_fields({type, sub_fields}, {acc, left_pad}) do
    {[format_fields(sub_fields, type, left_pad), padding(left_pad) | acc], left_pad}
  end

  defp do_format_fields(type, {acc, left_pad}) do
    {["\n", camelize(type), padding(left_pad) | acc], left_pad}
  end

  defp padding(0), do: ""
  defp padding(left_pad), do: Enum.map(1..left_pad, fn _ -> " " end)

  defp camelize(type), do: Absinthe.Utils.camelize(to_string(type), lower: true)
end
