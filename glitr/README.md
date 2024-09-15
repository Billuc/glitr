# glitr

Gleam typed routes library for type-safe fullstack development

[![Package Version](https://img.shields.io/hexpm/v/glitr)](https://hex.pm/packages/glitr)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr/)

```sh
gleam add glitr
```
```gleam
import glitr
import glitr/body
import glitr/route
import glitr/path
import glitr_lustre
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
  let get_all_todos_route = route.new()
    |> with_path(path.static_path(["todos"]))
    |> with_response_body(body.json_body(encoder, decoder))

  // This route can be shared and used by both frontend and backend applications

  // Here is an example for a frontend lustre application using glitr_lustre
  glitr_lustre.create_factory()
    |> glitr_lustre.with_port(2345)
    |> glitr_lustre.for_route(get_all_todos_route)
    |> glitr_lustre.with_path(Nil) // For now, this is necessary
    |> glitr_lustr.send(
      fn(todos) { ServerSentTodos(todos) }, // ServerSentTodos is a Lustre message
      fn(_err) { effect.none() } // This is for error handling
    )
}
```

Further documentation can be found at <https://hexdocs.pm/glitr>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
