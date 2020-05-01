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

      def document_for(type, nesting \\ 3) do
        document_for(unquote(schema), type, nesting)
      end
    end
  end
end
