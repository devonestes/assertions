defmodule Assertions.AbsintheCase do
  @moduledoc """
  A wrapper for `ExUnit.Case` that provides all assertions in the library and is configured
  especially for testing Absinthe applications.
  """

  use ExUnit.CaseTemplate

  using(opts) do
    schema =
      opts
      |> Keyword.fetch!(:schema)
      |> Macro.expand(__CALLER__)

    quote do
      import Assertions
      import Assertions.Absinthe

      def fields_for(type, nesting \\ 3) do
        fields_for(unquote(schema), type, nesting)
      end

      def document_for(type, nesting \\ 3, overrides \\ []) do
        document_for(unquote(schema), type, nesting, overrides)
      end

      def assert_response_equals(document, expected_response, options) when is_list(options) do
        assert_response_equals(unquote(schema), document, expected_response, options)
      end

      def assert_response_equals(schema, document, expected_response) do
        assert_response_equals(schema, document, expected_response, [])
      end

      def assert_response_equals(document, expected_response) do
        assert_response_equals(unquote(schema), document, expected_response, [])
      end

      defmacro assert_response_matches(document, options \\ [], expr) do
        schema = unquote(schema)

        quote do
          assert_response_matches(
            unquote(schema),
            unquote(document),
            unquote(options),
            unquote(expr)
          )
        end
      end
    end
  end
end
