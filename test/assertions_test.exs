defmodule AssertionsTest do
  # We can't run these async because we're capturing IO in most of them.
  use Assertions.Case
  doctest Assertions

  import ExUnit.CaptureIO, only: [capture_io: 1]

  describe "assert_lists_equal/2" do
    test "gives a really great error message" do
      defmodule AssertListsEqual.Two do
        use Assertions.Case, async: true

        test "fails" do
          assert_lists_equal([1, 2, 3], [1, 4, 2])
        end
      end

      output = run_tests()
      assert output =~ "Comparison of each element failed!"
      assert output =~ "assert_lists_equal([1, 2, 3], [1, 4, 2])"

      assert output =~
               "arguments:\e[0m\n\n         # 1\n         [1, 2, 3]\n\n         # 2\n         [1, 4, 2]\n\n     \e[36mleft:  \e[0m[\e[31m3\e[0m]\n     \e[36mright: \e[0m[\e[32m4\e[0m]\n     \e[36m"
    end
  end

  describe "assert_lists_equal/3" do
    test "gives a really great error messages" do
      defmodule AssertListsEqual.Three do
        use Assertions.Case, async: true

        test "fails with comparison" do
          left = ["dog", "cat"]
          right = ["lion", "dog"]
          assert_lists_equal(left, right, &(String.length(&1) == String.length(&2)))
        end

        test "fails with message" do
          assert_lists_equal([1, 2, 3], [1, 4, 2], "Not actually equal!")
        end
      end

      output = run_tests()
      assert output =~ "Comparison of each element failed!"

      assert output =~
               "assert_lists_equal(left, right, &(String.length(&1) == String.length(&2)))"

      assert output =~
               "arguments:\e[0m\n\n         # 1\n         [\"dog\", \"cat\"]\n\n         # 2\n         [\"lion\", \"dog\"]\n\n         # 3\n         #Function<1.79374689/2 in AssertionsTest.AssertListsEqual.Three.\"test fails with comparison\"/1>\n\n     \e[36mleft:  \e[0m[\e[31m\"cat\"\e[0m]\n     \e[36mright: \e[0m[\e[32m\"lion\"\e[0m]"

      assert output =~ "Not actually equal!"
      assert output =~ "assert_lists_equal([1, 2, 3], [1, 4, 2], \"Not actually equal!\")"

      assert output =~
               "arguments:\e[0m\n\n         # 1\n         [1, 2, 3]\n\n         # 2\n         [1, 4, 2]\n\n         # 3\n         \"Not actually equal!\"\n\n     \e[36mleft:  \e[0m[\e[31m3\e[0m]\n     \e[36mright: \e[0m[\e[32m4\e[0m]"
    end
  end

  defp run_tests do
    ExUnit.Server.modules_loaded()
    capture_io(fn -> ExUnit.run() end)
  end
end
