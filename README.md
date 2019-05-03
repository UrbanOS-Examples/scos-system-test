# ScosSystemTest

**TODO: Add description**

# Performance 

This module will generate a given number of data sets with a given number of records each, and post them to andi. 
You can also specifiy the andi url that you want to post the data to, as well as the test data generator url.
You can run this locally via iex. the options are passed as a keyword list like below: 
```
iex -S mix
ScosSystemTest.Performance.run([record_count: 10, dataset_count: 2, andi_url: 'https://andi.staging.internal.smartcolumbusos.com', tdg_url: 'http://data-generator.testing'])
```

Currently, this is not runnable through jenkins.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `scos_system_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scos_system_test, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/scos_system_test](https://hexdocs.pm/scos_system_test).

