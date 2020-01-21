defmodule AssertionsTest do
  # We can't run these async because we're capturing IO in most of them.
  use Assertions.Case
  doctest Assertions

  import ExUnit.CaptureIO, only: [capture_io: 1]

  describe "assert!/1" do
    test "fails if either side of >, >=, < or <= is nil" do
      assert!(nil > 0)
    rescue
      error in [ExUnit.AssertionError] ->
        assert nil == error.left
        assert 0 == error.right
        assert "assert!(nil > 0)" == Macro.to_string(error.expr)
        assert error.message == "`nil` is not allowed as an argument to `>` when using `assert!`"
    end
  end

  describe "refute!/1" do
    test "fails if either side of >, >=, < or <= is nil" do
      refute!(nil > 0)
    rescue
      error in [ExUnit.AssertionError] ->
        assert nil == error.left
        assert 0 == error.right
        assert "refute!(nil > 0)" == Macro.to_string(error.expr)
        assert error.message == "`nil` is not allowed as an argument to `>` when using `refute!`"
    end
  end

  describe "assert_lists_equal/2" do
    test "works when composed with other assertions" do
      list1 = [DateTime.utc_now(), DateTime.utc_now()]
      list2 = [DateTime.utc_now(), DateTime.utc_now()]
      assert_lists_equal(list1, list2, &assert_structs_equal(&1, &2, [:year, :month]))
    end
  end

  describe "assert_lists_equal/3" do
    test "works with comparisons that raise an error instead of returning false" do
      list1 = [%{foo: 1}, %{foo: 2}, %{foo: 3}]
      list2 = [%{foo: 2}, %{foo: 1}, %{foo: 3}]
      assert_lists_equal(list1, list2, &assert_maps_equal(&1, &2, [:foo]))
    end
  end

  describe "assert_map_in_list/3" do
    test "fails with a list of keys to compare by" do
      defmodule AssertMapInList do
        use Assertions.Case, async: true

        test "fails" do
          assert_map_in_list(%{a: :b, c: :d}, [%{a: :b, c: :e}], [:a, :c])
        end
      end

      output = run_tests()
      assert output =~ "Map matching the values for keys `:a, :c` not found"
    end
  end

  describe "assert_structs_equal/3" do
    defmodule Nested do
      defstruct [:key, :list, :map]
    end

    test "works with nested assertions" do
      first = %Nested{key: :value, list: [1, 2, 3], map: %{a: :a}}
      second = %Nested{key: :value, list: [1, 3, 2], map: %{"a" => :a}}

      assert_structs_equal(first, second, fn left, right ->
        assert left.key == right.key
        assert_lists_equal(left.list, right.list)
        assert_maps_equal(left.map, right.map, &(&1.a == &2["a"]))
      end)
    end
  end

  describe "assert_raise/1" do
    test "doesn't override ExUnit's assert_raise/2 or assert_raise/3" do
      assert_raise(ExUnit.AssertionError, fn ->
        assert_raise(fn ->
          first = 1
          second = 2
          first / second
        end)
      end)

      regex = ~r/Expected exception but nothing was raised/

      assert_raise ExUnit.AssertionError, regex, fn ->
        assert_raise(fn ->
          first = 1
          second = 2
          first / second
        end)
      end
    end
  end

  defp run_tests do
    ExUnit.Server.modules_loaded()
    capture_io(fn -> ExUnit.run() end)
  end
end
