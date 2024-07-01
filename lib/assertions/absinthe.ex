defmodule Assertions.Absinthe do
  @moduledoc """
  Helpful assertions for testing Absinthe applications.

  This module contains some functions that make it much simpler and safer to test Absinthe
  applications. Probably the most common issue that is seen in Absinthe applications is untested
  resolver functions and fields, and it's nearly impossible to tell using just code coverage
  which fields are tested or not.

  These functions make it trivially easy to generate very large, comprehensive queries for our
  types in Absinthe that will resolve every field in that type (and any number of subtypes as
  well to a given level of depth), and by default makes it so that we're either testing
  equality of the response or testing a pattern match on the response.

  While many of these functions explicitly take the schema as the first argument, if you want to
  simplify things you can use the provided ExUnit case template like so:

    `use Assertions.AbsintheCase, async: true, schema: MyApp.Schema`

  and then all functions in this module will not need the schema passed explicitly into it.
  """
  if match?({:module, _}, Code.ensure_compiled(Absinthe)) do
    require Assertions

    require ExUnit.Assertions

    # We need to unwrap non_null and list sub-fields
    @doc """
    Returns all fields in a type and any sub-types down to a limited depth of nesting (default `3`).

    This is helpful for converting a struct or map into an expected response that is a bare map
    and which can be used in some of the other assertions below.
    """
    @spec fields_for(module(), atom(), non_neg_integer()) :: list(fields) | atom()
          when fields: atom() | {atom(), list(fields)}
    def fields_for(schema, %{of_type: type}, nesting) do
      fields_for(schema, type, nesting)
    end

    def fields_for(schema, type, nesting) do
      type
      |> schema.__absinthe_type__()
      |> get_fields(schema, nesting)
    end

    @doc """
    Returns a document containing the fields in a type and any sub-types down to a limited depth of
    nesting (default `3`).

    This is helpful for generating a document to use for testing your GraphQL API. This function
    will always return all fields in the given type, ensuring that there aren't any accidental
    fields with resolver functions that aren't tested in at least some fashion.

    ## Example

        document_for(:user, 2)
        \"""
        name
        age
        posts {
          title
          subtitle
        }
        comments {
          body
        }
        \"""
    """
    @spec document_for(module(), atom(), non_neg_integer(), Keyword.t()) :: String.t()
    def document_for(schema, type, nesting, overrides) do
      schema
      |> fields_for(type, nesting)
      |> merge_overrides(overrides)
      |> format_fields(type, 10, schema)
      |> List.to_string()
    end

    @doc ~S"""
    Assert that the response for sending `document` equals `expected_response`.

    This is helpful when you want to exhaustively test something by asserting equality on every
    field in the response.

    ## Example

        query = "{ user { #{document_for(:user, 2)} } }"
        expected = %{"user" => %{"name" => "Bob", "posts" => [%{"title" => "A post"}]}}
        assert_response_equals(query, expected)
    """
    @spec assert_response_equals(module(), String.t(), map(), Keyword.t()) :: :ok | no_return()
    def assert_response_equals(schema, document, expected_response, options) do
      ExUnit.Assertions.assert {:ok, %{data: response}} = Absinthe.run(document, schema, options)
      Assertions.assert_maps_equal(response, expected_response, Map.keys(response))
    end

    @doc ~S"""
    Assert that the response for sending `document` matches `expr`.

    This is helpful when you want to test some but not all fields in the returned response, or
    would like to break up your assertions by binding variables in the body of the match and then
    making separate assertions further down in your test.

    ## Example

        query = "{ user { #{document_for(:user, 2)} } }"
        assert_response_matches(query) do
          %{"user" => %{"name" => "B" <> _, "posts" => posts}}
        end
         assert length(posts) == 1
    """
    @spec assert_response_matches(module(), String.t(), Keyword.t(), Macro.expr()) ::
            :ok | no_return()
    defmacro assert_response_matches(schema, document, options, do: expr) do
      quote do
        ExUnit.Assertions.assert {:ok, %{data: unquote(expr)}} =
                Absinthe.run(unquote(document), unquote(schema), unquote(options))
      end
    end

    # We don't include any other objects in the list when we've reached the end of our nesting,
    # otherwise the resulting document would be invalid because we need to select sub-fields of
    # all objects.
    defp get_fields(%{fields: _}, _, 0) do
      :reject
    end

    # We can't use the struct expansion directly here, because then it becomes a compile-time
    # dependency and will make compilation fail for projects that doesn't use Absinthe.
    defp get_fields(%struct{fields: fields} = type, schema, nesting)
        when struct == Absinthe.Type.Interface do
      interface_fields =
        Enum.reduce(fields, [], fn {_, value}, acc ->
          case fields_for(schema, value.type, nesting - 1) do
            :reject -> acc
            :scalar -> [String.to_atom(value.name) | acc]
            list -> [{String.to_atom(value.name), list} | acc]
          end
        end)

      implementors = Map.get(schema.__absinthe_interface_implementors__(), type.identifier)

      implementor_fields =
        Enum.map(implementors, fn type ->
          {type, fields_for(schema, type, nesting) -- interface_fields -- [:__typename]}
        end)

      {interface_fields, implementor_fields}
    end

    defp get_fields(%struct{types: types}, schema, nesting) when struct == Absinthe.Type.Union do
      {[], Enum.map(types, &{&1, fields_for(schema, &1, nesting)})}
    end

    defp get_fields(%{fields: fields}, schema, nesting) do
      Enum.reduce(fields, [], fn {_, value}, acc ->
        case fields_for(schema, value.type, nesting - 1) do
          :reject -> acc
          :scalar -> [String.to_atom(value.name) | acc]
          list when is_list(list) -> [{String.to_atom(value.name), list} | acc]
          tuple -> [{String.to_atom(value.name), tuple} | acc]
        end
      end)
    end

    defp get_fields(_, _, _) do
      :scalar
    end

    defp format_fields({interface_fields, implementor_fields}, _, 10, schema) do
      interface_fields =
        interface_fields
        |> Enum.reduce({[], 12}, &do_format_fields(&1, &2, schema))
        |> elem(0)

      implementor_fields =
        implementor_fields
        |> Enum.map(fn {type, fields} ->
          type_info = schema.__absinthe_type__(type)
          [_ | rest] = format_fields(fields, type, 12, schema)
          fields = ["...on #{type_info.name} {\n" | rest]
          [padding(12), fields]
        end)

      Enum.reverse([implementor_fields | interface_fields])
    end

    defp format_fields(fields, _, 10, schema) when is_list(fields) do
      fields =
        fields
        |> Enum.reduce({[], 12}, &do_format_fields(&1, &2, schema))
        |> elem(0)

      Enum.reverse(fields)
    end

    defp format_fields({interface_fields, implementor_fields}, type, left_pad, schema)
        when is_list(interface_fields) do
      interface_fields =
        interface_fields
        |> Enum.reduce({["#{camelize(type)} {\n"], left_pad + 2}, &do_format_fields(&1, &2, schema))
        |> elem(0)

      implementor_fields =
        implementor_fields
        |> Enum.map(fn {type, fields} ->
          type_info = schema.__absinthe_type__(type)
          [_ | rest] = format_fields(fields, type, left_pad + 2, schema)
          fields = ["...on #{type_info.name} {\n" | rest]
          [padding(left_pad + 2), fields]
        end)

      Enum.reverse(["}\n", padding(left_pad), implementor_fields | interface_fields])
    end

    defp format_fields(fields, type, left_pad, schema) do
      fields =
        fields
        |> Enum.reduce({["#{camelize(type)} {\n"], left_pad + 2}, &do_format_fields(&1, &2, schema))
        |> elem(0)

      Enum.reverse(["}\n", padding(left_pad) | fields])
    end

    defp do_format_fields({type, sub_fields}, {acc, left_pad}, schema) do
      {[format_fields(sub_fields, type, left_pad, schema), padding(left_pad) | acc], left_pad}
    end

    defp do_format_fields(type, {acc, left_pad}, _) do
      {["\n", camelize(type), padding(left_pad) | acc], left_pad}
    end

    defp padding(0), do: ""
    defp padding(left_pad), do: Enum.map(1..left_pad, fn _ -> " " end)

    defp camelize(type), do: Absinthe.Utils.camelize(to_string(type), lower: true)

    defp merge_overrides({key, values}, [{_, _} | _] = fields) when is_atom(key) and is_list(values) do
      Keyword.update!(fields, key, fn field_value ->
        Enum.reduce(values, field_value, &merge_overrides/2)
      end)
    end

    defp merge_overrides({key, replacement_key}, fields)
        when is_atom(key) and is_binary(replacement_key) do
      Enum.map(fields, fn
        ^key -> replacement_key
        {^key, value} -> {replacement_key, value}
        value -> value
      end)
    end

    defp merge_overrides(fields, []) do
      fields
    end

    defp merge_overrides(fields, overrides) do
      Enum.reduce(overrides, fields, &merge_overrides/2)
    end
  end
end
