# glitr_convert_sql

[![Package Version](https://img.shields.io/hexpm/v/glitr_convert_sql)](https://hex.pm/packages/glitr_convert_sql)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr_convert_sql/)

**Create SQL requests effortlessly using glitr_convert**

## Installation

```sh
gleam add glitr_convert_sql
```

## Usage

```gleam
import gleam/io
import glitr/convert as c
import glitr/convert/sql

pub type User {
  User(id: String, name: String, age: Int)
}

pub fn user_converter() -> c.Converter(User) {
  c.object({
    use id <- c.parameter
    use name <- c.parameter
    use age <- c.parameter
    use <- c.constructor
    User(id:, name:, age:)
  })
  |> c.field("id", fn(v) { Ok(v.id) }, c.string())
  |> c.field("name", fn(v) { Ok(v.name) }, c.string())
  |> c.field("age", fn(v) { Ok(v.age) }, c.int())
  |> c.to_converter
}

pub fn main() {
  let alice = User("1", "Alice", 24)

  sql.insert("users", user_converter(), [alice])
  |> io.debug
  // INSERT INTO users (id, name, age) VALUES ('1', 'Alice', 24);

  let happy_birthday_alice = User(..alice, age: 25)

  sql.update("users", user_converter(), alice, "id")
  |> io.debug
  // UPDATE users SET name='Alice', age=25 WHERE id='1';

  sql.select("users", user_converter())
  |> io.debug
  // SELECT id, name, age FROM users;
}
```

Further documentation can be found at <https://hexdocs.pm/glitr_convert_sql>.

## Features

- Select all requests
- Insert requests
- Update requests

## Backlog

- Select + where requests
- Delete requests
- Integrate more features like order by, returning and joins

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
