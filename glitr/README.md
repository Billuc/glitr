# glitr

Gleam typed routes library for type-safe fullstack development

[![Package Version](https://img.shields.io/hexpm/v/glitr)](https://hex.pm/packages/glitr)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr/)

```sh
gleam add glitr
```
```gleam
import glitr
import glitr/utils
import gleam/json
import gleam/dynamic
import gleam/http

pub type Todo {
  Todo(id: String, title: String)
}

fn encoder(t: Todo) -> json.Json {
  json.object([
    #("id", json.string(t.id)),
    #("title", json.string(t.title)),
  ])
}

fn decoder(
  value: dynamic.Dynamic,
) -> Result(Todo, List(dynamic.DecodeError)) {
  value
  |> dynamic.decode2(
    Todo,
    dynamic.field("id", dynamic.string),
    dynamic.field("title", dynamic.string),
  )
}

pub fn main() {
  let todo_converter = glitr.JsonConverter(encoder, decoder)
  let get_all_todos_route = glitr.Route(
    http.Get,
    http.Http,
    "localhost",
    2345,
    False,
    utils.simple_path_converter(["todos"]),
    utils.no_body_converter(),
    todo_converter
  )

  // This route can be shared and used by both frontend and backend applications

  // Here is an example for a frontend application
  let request = get_all_todos_route |> utils.to_request(Nil, Nil)

  // Use request as you wish (with glitr_lustre for example)
}
```

Further documentation can be found at <https://hexdocs.pm/glitr>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
