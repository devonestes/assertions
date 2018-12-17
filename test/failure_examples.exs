defmodule Assertions.FailureExamples do
  @moduledoc """
  This module is not run when running `mix test` because the file name doesn't
  follow the `*_test.exs` pattern. This is intentional. All of these examples
  fail, and this is to show how the diff is generated when using the
  `ExUnit.Console` formatter.
  """

  @path Path.expand("../tmp/file.txt", __DIR__)

  use Assertions.Case

  setup do
    on_exit(fn ->
      File.rm_rf(Path.dirname(@path))
    end)
  end

  describe "assert!/1" do
    test "fails" do
      assert!("A string")
    end
  end

  describe "refute!/1" do
    test "fails" do
      refute!(nil)
    end
  end

  describe "assert_lists_equal/2" do
    test "fails" do
      assert_lists_equal([1, 2, 3], [1, 4, 2])
    end
  end

  describe "assert_lists_equal/3" do
    test "fails when the third argument is a custom message" do
      assert_lists_equal([1, 2, 3], [1, 4, 2], "Didn't match!")
    end

    test "fails when the third argument is a custom function" do
      assert_lists_equal(["cat"], ["lion"], &(String.length(&1) == String.length(&2)))
    end
  end

  describe "assert_lists_equal/4" do
    test "fails" do
      left = ["cat"]
      right = ["lion"]
      comparison = &(String.length(&1) == String.length(&2))
      message = "Not the same length!"
      assert_lists_equal(left, right, comparison, message)
    end
  end

  describe "assert_map_in_list/3" do
    test "fails with atom keys" do
      map = %{first: :first, second: :second, not: :used, keys: :are, always: :pruned}
      list = [%{first: :first, second: :third, third: :fourth, a: :b, d: :e}]
      keys = [:first, :second]
      assert_map_in_list(map, list, keys)
    end

    test "fails with string keys" do
      map = %{"first" => :first, "second" => :second}
      list = [%{"first" => :first, "second" => :third}]
      keys = ["first", "second"]
      assert_map_in_list(map, list, keys)
    end

    test "fails with list keys" do
      map = %{["first"] => :first, ["second"] => :second}
      list = [%{["first"] => :first, ["second"] => :third}]
      keys = [["first"], ["second"]]
      assert_map_in_list(map, list, keys)
    end
  end

  describe "assert_maps_equal/3" do
    test "fails" do
      assert_maps_equal(
        %{first: :first, second: :second},
        %{first: :second, third: :third},
        [:first]
      )
    end
  end

  describe "assert_struct_in_list/3" do
    test "fails with struct/keys/list" do
      assert_struct_in_list(DateTime.utc_now(), [:year, :month], [Date.utc_today()])
    end

    test "fails with map/module/list" do
      map = Map.take(DateTime.utc_now(), [:year, :month])
      assert_struct_in_list(map, DateTime, [Date.utc_today()])
    end
  end

  describe "assert_structs_equal/3" do
    test "fails" do
      assert_structs_equal(
        DateTime.utc_now(),
        DateTime.utc_now(),
        [:year, :month, :millisecond, :microsecond]
      )
    end
  end

  describe "assert_all_have_value/3" do
    test "fails" do
      list = [
        %{key: :value, other: :pair},
        %{key: :pair, other: :value},
        [key: :list, other: :keyword]
      ]

      assert_all_have_value(list, :key, :value)
    end
  end

  describe "assert_changes_file/3" do
    test "fails when the file doesn't exist" do
      assert_changes_file @path, "hi" do
        File.write(@path, "hi")
      end
    end

    test "fails when the file matches before the expression is executed" do
      File.mkdir_p!(Path.dirname(@path))
      File.write(@path, "hi there, I'm pre-existing.")

      assert_changes_file @path, "hi" do
        File.write(@path, "hi")
      end
    end

    test "fails when the file doesn't exist after the expression is executed" do
      assert_changes_file @path, "hi" do
        File.mkdir_p!(Path.dirname(@path))
      end
    end

    test "fails when the file doesn't match the comparison" do
      assert_changes_file @path, "guten Tag" do
        File.mkdir_p!(Path.dirname(@path))
        File.write(@path, "hi")
      end
    end
  end

  describe "assert_creates_file/2" do
    test "fails when the file exists before the function" do
      File.mkdir_p!(Path.dirname(@path))
      File.write(@path, "hi")

      assert_creates_file @path do
        File.write(@path, "hi")
      end
    end

    test "fails when the file doesn't exist after the function" do
      assert_creates_file @path do
        File.mkdir_p!(Path.dirname(@path))
      end
    end
  end

  describe "assert_deletes_file/2" do
    test "fails when the file doesn't exist before the function" do
      assert_deletes_file @path do
        File.mkdir_p!(Path.dirname(@path))
      end
    end

    test "fails when the file exists after the function" do
      File.mkdir_p!(Path.dirname(@path))
      File.write(@path, "hi there")

      assert_deletes_file @path do
        File.write(@path, "I'm pre-existing.")
      end
    end
  end

  describe "assert_receive_only/2" do
    test "fails if it receives no messages" do
      assert_receive_only(:hello, 1)
    end

    test "fails if it receives the wrong message first" do
      send(self(), :hello_again)
      send(self(), [:hello])
      assert_receive_only([_])
    end

    test "fails if the messages are sent after the assert call" do
      Process.send_after(self(), :hello, 50)
      Process.send_after(self(), :hello_again, 20)
      assert_receive_only(:hello, 100)
    end

    test "fails if it receives an unexpected message after the expected pattern" do
      send(self(), :hello)
      send(self(), :hello_again)
      assert_receive_only(:hello)
    end
  end
end
