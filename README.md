# Assertions [![Hex Version](https://img.shields.io/hexpm/v/assertions.svg)](https://hex.pm/packages/assertions) [![Build Status](https://travis-ci.org/devonestes/assertions.svg?branch=master)](https://travis-ci.org/devonestes/assertions)

## Installation

Add `assertions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:assertions, "~> 0.10", only: :test}]
end
```

## Usage

### Importing

If you only want some assertions in a given module, then import just the
functions that you want to use. Otherwise you can simply call `import
Assertions` and all assertions will be directly available to your test code.

```elixir
def UsersTest do
  use ExUnit.Case, async: true

  require Assertions
  import Assertions, only: [assert_lists_equal: 2]

  # ...
end
```

Because these assertions are all macros, `Assertions` must be `require`d first
if you want to call a function like `Assertions.assert_map_in_list/3`.

Importing assertions in an existing test case (like `MyApp.DataCase` in a
Phoenix application) is typically recommended.

Here is an example of how you'd add assertions to your `MyApp.DataCase`:
```elixir
defmodule MayApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import MyApp.DataCase

      # Add the following line
      import Assertions
    end
  end
end
```

### Assertions.Case

If you want to have all assertions available to you by default, you can use the
provided `Assertions.Case` macro. This is a very small wrapper around
`ExUnit.Case`, and imports all assertions for your use.

```elixir
def MyApp.UserTest do
  use Assertions.Case, async: true

  # ...
end
```

But importing assertions in an existing test case (like `MyApp.DataCase` in a
Phoenix application) is typically recommended.

## Why use `assertions`?

There are three things this library offers:

1) Concise, expressive assertions for common types of tests
2) Flexibility through composition
3) Exceptional error messages

Let's look at examples of all of these points. Let's say you have the following
test:

```elixir
defmodule UsersTest do
  use ExUnit.Case, async: true

  describe "update_all/2" do
    test "updates the given users in the database and returns those updated users" do
      alice = Factory.insert(:user, name: "Alice")
      bob = Factory.insert(:user, name: "Bob")

      updated_names = 
        [{alice, %{name: "Alice A."}, {bob, %{name: "Bob B."}}}]
        |> Users.update_all()
        |> Enum.map(& &1.name)

      all_user_names =
        User
        |> Repo.all()
        |> Enum.map(& &1.name)

      Enum.each(["Alice A.", "Bob B."], fn name ->
        assert name in updated_names
        assert name in all_user_names
      end
    end
  end
end
```

Testing elements in lists is a very common thing to do, but it's also very
tricky! If you want to test those lists, you can't assert that they're equal
because order matters with lists. Also, with those structs, you can't compare
them directly because maybe there are associations that might be loaded in one
struct but not loaded in the other. The above test is the best you can do to
accurately test those changes with the standard testing tools.

### Expressive assertions

But, with `assertions`, you can write that test like this:

```elixir
defmodule UsersTest do
  use ExUnit.Case, async: true
  import Assertions, only: [assert_lists_equal: 2]

  describe "update_all/2" do
    test "updates the given users in the database and returns those updated users" do
      alice = Factory.insert(:user, name: "Alice")
      bob = Factory.insert(:user, name: "Bob")

      result = Users.update_all([{alice, %{name: "Alice A."}, {bob, %{name: "Bob B."}}}

      result
        |> Enum.map(& &1.name)
        |> assert_lists_equal(["Alice A.", "Bob B."])

      assert_lists_equal(result, Users.list_all(), &assert_structs_equal(&1, &2, [:name]))
    end
  end
end
```

`assert_lists_equal` asserts that the two lists are equal without taking order
into account, which is most often the assertion that we want to make when
comparing lists.

### Flexibility through composition

But `assert_lists_equal` also solves the other problem we had when we wanted to
compare lists of structs. That second assertion:

```elixir
assert_lists_equal(result, Users.list_all(), &assert_structs_equal(&1, &2, [:name]))
```

is comparing that the two lists are equal, but we give it a custom comparison
function. If we were to just use `assert_lists_equal(results, Users.list_all())`,
then all values for all keys in those structs must be equal for them to be
considered equal, and this can be very error prone, especially when dealing with
structs used as Ecto resources that can have associations that are either loaded
or not loaded.

This ability to compose behavior of assertions lets you easily customize your
assertions for each of your tests.

### Exceptional error messages

`assertions` always tries to give you the most helpful error messages possible
for any test failures to make it easy to see what went wrong and how to fix it.
Lets look at a different test:

```elixir
test "a map in a list matches the value of this other map" do
  map = %{key: :value, stores: :are, really: :helpful}

  list = [
    %{big: :map, with: :lots, of: :keys},
    %{another: :big, store: :with, key: :values}
  ]

  assert Enum.any?(list, fn map_in_list ->
            Map.get(map_in_list, :key) == map.key
          end)
end
```

The output you get from that failure looks like this:

```
     Expected truthy, got false
     code: assert Enum.any?(list, fn map_in_list -> Map.get(map_in_list, :key) == map.key() end)
     arguments:

         # 1
         [
           %{big: :map, of: :keys, with: :lots},
           %{another: :big, key: :values, store: :with}
         ]

         # 2
         #Function<21.25555998/1 in Assertions.FailureExamples."test example"/1>

     stacktrace:
       test/failure_examples.exs:207: (test)
```

That's not really helpful. What we wanted to know was essentially "is a map with
the same values for a certain key in this list?", and we got no help in finding
what went wrong. With `assertions` we can write that same assertion like this:

```elixir
test "a map in a list matches the value of this other map" do
  map = %{key: :value, stores: :are, really: :helpful}

  list = [
    %{big: :map, with: :lots, of: :keys},
    %{another: :big, store: :with, key: :values}
  ]

  assert_map_in_list(map, list, [:key])
end
```

And then the output looks like this:

```
     Map matching the values for keys `:key` not found
     code:  assert_map_in_list(map, list, [:key])
     arguments:

         # 1
         %{key: :value, really: :helpful, stores: :are}

         # 2
         [
           %{big: :map, of: :keys, with: :lots},
           %{another: :big, key: :values, store: :with}
         ]

     left:  %{key: :value}
     right: [%{}, %{key: :values}]
     stacktrace:
       test/failure_examples.exs:206: (test)
```

The error message there in the `left` and `right` keys shrinks down the output
to only show us the relevant information. I can see here that one map didn't
contain the key we wanted, and the value was different in the other.
