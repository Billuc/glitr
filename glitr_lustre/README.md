# glitr_lustre

Interface for lustre to use Glitr's typed routes

[![Package Version](https://img.shields.io/hexpm/v/glitr_lustre)](https://hex.pm/packages/glitr_lustre)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr_lustre/)

```sh
gleam add glitr_lustre
```
```gleam
import glitr_lustre
import gleam/http
import lustre
import lustre/effect

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    TodoAdded(title) -> #(model, glitr_lustre.create_factory()
      |> glitr_lustre.with_scheme(http.Http)
      |> glitr_lustre.with_host("localhost")
      |> glitr_lustre.with_port(2345)
      |> glitr_lustre.for_route(todo_service() |> create_route)
      |> glitr_lustre.with_body(CreateTodo(title))
      |> glitr_lustre.send(ServerCreatedTodo, fn(_) { effect.none() })
    )
    ServerCreatedTodo(Ok(new_todo)) -> #([new_todo, ..model], effect.none())
    _ -> #(model, effect.none())
  }
}
```

Further documentation can be found at <https://hexdocs.pm/glitr_lustre>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
