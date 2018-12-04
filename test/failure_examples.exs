defmodule Assertions.FailureExamples do
  @moduledoc """
  This module is not run when running `mix test` because the file name doesn't
  follow the `*_test.exs` pattern. This is intentional. All of these examples
  fail, and this is to show how the diff is generated when using the
  `ExUnit.Console` formatter.
  """

  use Assertions.Case, async: true

  defmodule User do
    defstruct [:id, :name, :age, :address]
  end

  describe "assert_lists_equal/2" do
    test "fails" do
      assert_lists_equal([1, 2, 3], [1, 4, 2])
    end
  end

  describe "assert_lists_equal/3" do
    test "fails when the third argument is a custom message" do
    end

    test "fails when the third argument is a custom function" do
    end
  end

  describe "assert_lists_equal/4" do
    test "fails" do
    end
  end
end
