# glitr_convert

[![Package Version](https://img.shields.io/hexpm/v/glitr_convert)](https://hex.pm/packages/glitr_convert)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr_convert/)

**Encode and decode from and to Gleam types effortlessly !**

Define a converter once and encode and decode as much as you want.

## Installation

```sh
gleam add glitr_convert
```

## Usage

```gleam
import glitr_convert/converter as c
import gleam/json

type Person {
  Person(name: String, age: Int)
}

pub fn main() {
  let converter = c.object({
    use name <- c.parameter
    use age <- c.parameter
    use <- c.constructor
    Person(name:, age:)
  })
  |> field("name", fn(v) { Ok(v.name) }, c.string())
  |> field("age", fn(v) { Ok(v.age) }, c.int())
  |> c.to_converter

  converter
  |> c.json_encode(Person("Anna", 21))
  |> json.to_string
  // '{"name": "Anna", "age": 21}'

  "{\"name\": \"Bob\", \"age\": 36}"
  |> json.decode(c.json_decode(converter, _))
  // Ok(Person("Bob", 36))
}
```

Further documentation can be found at <https://hexdocs.pm/glitr_convert>.

## Features

- Javascript and Erlang targets
- Converters for all basic types (except BitArray)
- Define converters for List, Dict, Result & Option
- Build decoders for custom objects and enums
- Encode and decode to JSON.

## Potential developments

- Add BitArray support
- Add Yaml conversion

Feel free to open PRs and issues if you want more features !

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
