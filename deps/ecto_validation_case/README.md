Ecto.ValidationCase
==================

[![Build Status](https://travis-ci.org/danielberkompas/ecto_validation_case.svg?branch=master)](https://travis-ci.org/danielberkompas/ecto_validation_case)
[![Inline docs](http://inch-ci.org/github/danielberkompas/ecto_validation_case.svg?branch=master)](http://inch-ci.org/github/danielberkompas/ecto_validation_case)

Simplify your [Ecto][ecto] model validation tests. Loosely inspired by [shoulda
matchers][shoulda], but simpler.

## Sample

```elixir
defmodule MyApp.UserTest do
  use ExUnit.Case
  use Ecto.ValidationCase, model: MyApp.User

  test "requires password to be 10 chars long" do
    rejects "password",    for: :password, message: "too short"
    accepts "password123", for: :password
  end
end
```

## Rationale

Rather than create a matching test helper function for each of the valiations
that [Ecto][ecto] supports, this library intentionally keeps things simple,
providing only `accepts/2` and `rejects/2`. Why?

- The api very easy to remember, which makes validation tests more likely to be
  written.
- The tests are more explicit, with a minimum of magic. It is very clear exactly
  what values are being tested, for which fields, and which error messages
  should be returned.

## Installation

You can install `Ecto.ValidationCase` from hex. First, change your `deps` in
`mix.exs`:

```elixir
def deps do
  [{:ecto_validation_case, ">= 0.1.0"}]
end
```

Then run `mix deps.get` to install.

## License

MIT. See [LICENSE](/LICENSE) and [NOTICE](/NOTICE) for more details.

[ecto]: https://github.com/elixir-lang/ecto
[shoulda]: http://matchers.shoulda.io/
