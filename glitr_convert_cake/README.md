# glitr_convert_cake

[![Package Version](https://img.shields.io/hexpm/v/glitr_convert_cake)](https://hex.pm/packages/glitr_convert_cake)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr_convert_cake/)

**Easily select, insert, update and decode values from a database using cake and glitr_convert** 

## Installation

```sh
gleam add glitr_convert_cake
```

## Usage

```gleam
import cake
import cake/dialect/postgres_dialect
import cake/insert as i
import cake/param
import cake/select as s
import cake/update as u
import cake/where as w
import gleam/io
import gleam/pgo
import gleam/result
import glitr/convert as c
import glitr/convert/cake as cc

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
  let alice = User("1", "Alice", 21)
  let bob = User("2", "Bob", 22)
  let table_name = "users"

  let create_query = i.new()
    |> i.table(table_name)
    |> cc.cake_insert(user_converter(), [alice, bob])
    |> i.to_query
    // Execute query

  let update_query = u.new()
    |> u.table(table_name)
    |> cc.cake_update(user_converter(), User(..alice, age: 36))
    |> u.where(w.col("id") |> w.eq(w.string(alice.id)))
    |> u.to_query
    // Execute query

  let select_all_query = s.new()
    |> s.from_table(table_name)
    |> cc.cake_select_fields(user_converter())
    |> s.to_query

  // Example: executing query with pgo and decoding the values with glitr_convert_cake
  let query = select_all_query |> postgres_dialect.read_query_to_prepared_statement
  
  pgo.execute(
    query |> cake.get_sql,
    db_connection, // Connection to a Postgres DB
    query |> cake.get_params |> list.map(map_param),
    cc.cake_decode(user_converter())
  )
  |> result.map(fn (res) { res.rows })
  |> io.debug
  // Ok(List(User("1", "Alice", 36), User("2", "Bob", 22)))
}

fn map_param(p: param.Param) -> pgo.Value {
  case p {
    param.BoolParam(v) -> pgo.bool(v)
    param.FloatParam(v) -> pgo.float(v)
    param.IntParam(v) -> pgo.int(v)
    param.StringParam(v) -> pgo.text(v)
    param.NullParam -> pgo.null()
  }
}
```

Further documentation can be found at <https://hexdocs.pm/glitr_convert_cake>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
