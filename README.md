# Assertions [![Hex Version](https://img.shields.io/hexpm/v/assertions.svg)](https://hex.pm/packages/assertions) [![Build Status](https://travis-ci.org/devonestes/assertions.svg?branch=master)](https://travis-ci.org/devonestes/assertions)

## Installation

Add `assertions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:assertions, "~> 0.5", only: :test}]
end
```

## Usage

### Importing

If you only want some assertions in a given module, all assertions are available
for importing into any test you want.

```elixir
def MyApp.UserTest do
  use ExUnit.Case, async: true

  import Assertions, only: [lists_equal?: 2]

  # ...
end
```

Because some assertions are macros, you may need to require the module before
importing.

```elixir
def MyApp.UserTest do
  use ExUnit.Case, async: true

  require Assertions
  import Assertions, only: [receive_only?: 1]

  # ...
end
```

Importing assertions in a common test case (like `MyApp.DataCase` in a Phoenix
application) is a common pattern and highly recommended.

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
