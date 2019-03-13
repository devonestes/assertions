defmodule Assertions.Case do
  @moduledoc """
  A wrapper for `ExUnit.Case` that provides all assertions in the library.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      require Assertions
      import Assertions
      import Assertions.Comparisons, only: [maps_equal?: 3, maps_equal?: 2]
    end
  end
end
