# glitr_wisp

Interface for wisp to use Glitr's typed routes

[![Package Version](https://img.shields.io/hexpm/v/glitr_wisp)](https://hex.pm/packages/glitr_wisp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glitr_wisp/)

```sh
gleam add glitr_wisp
```
```gleam
import glitr_wisp
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use _req <- web.middleware(req)

  glitr_wisp.for(req)
  |> glitr_wisp.try(todo_routes.get_all(), todo_service.get_all(ctx, _))
  |> glitr_wisp.try(todo_routes.get(), todo_service.get(ctx, _))
  |> glitr_wisp.try(todo_routes.create(), todo_service.create(ctx, _))
  |> glitr_wisp.try(todo_routes.update(), todo_service.update(ctx, _))
  |> glitr_wisp.try(todo_routes.delete(), todo_service.delete(ctx, _))
  |> glitr_wisp.unwrap
}
```

Further documentation can be found at <https://hexdocs.pm/glitr_wisp>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
