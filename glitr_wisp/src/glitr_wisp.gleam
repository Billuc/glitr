import gleam/bool
import gleam/dynamic
import gleam/json
import gleam/result
import gleam/string_builder
import glitr
import glitr_wisp/errors
import wisp

pub type Router {
  Router(req: wisp.Request)
}

pub type RouteOptions(p, b) {
  RouteOptions(path: p, body: b)
}

pub fn for(req: wisp.Request) -> Result(Router, wisp.Response) {
  Ok(Router(req))
}

pub fn try(
  router_res: Result(Router, wisp.Response),
  route: glitr.Route(p, b, res),
  handler: fn(RouteOptions(p, b)) -> Result(res, errors.AppError),
) -> Result(Router, wisp.Response) {
  use router <- result.try(router_res)

  let result = receive(router.req, route, handler)

  case result {
    Ok(response) -> Error(response)
    Error(Nil) -> Ok(router)
  }
}

pub fn unwrap(router_res: Result(Router, wisp.Response)) -> wisp.Response {
  case router_res {
    Ok(_) -> wisp.not_found()
    Error(response) -> response
  }
}

fn receive(
  req: wisp.Request,
  route: glitr.Route(p, b, res),
  handler: fn(RouteOptions(p, b)) -> Result(res, errors.AppError),
) -> Result(wisp.Response, Nil) {
  use <- bool.guard(req.method != route.method, Error(Nil))
  use path <- handle_path(req, route)
  use body <- handle_body(req, route)

  use <- handle_result

  let result = handler(RouteOptions(path, body))
  result
  |> result.map(route.res_body_converter.encoder)
  |> result.map(json.to_string_builder)
}

fn handle_path(
  req: wisp.Request,
  route: glitr.Route(p, _, _),
  callback: fn(p) -> wisp.Response,
) -> Result(wisp.Response, Nil) {
  let path_result = req |> wisp.path_segments |> route.path_converter.decoder

  case path_result {
    Ok(path) -> Ok(callback(path))
    Error(_) -> Error(Nil)
  }
}

fn handle_body(
  req: wisp.Request,
  route: glitr.Route(_, b, _),
  callback: fn(b) -> wisp.Response,
) -> wisp.Response {
  let call_callback = fn(res) {
    case res {
      Ok(value) -> callback(value)
      Error(_) ->
        wisp.bad_request()
        |> wisp.string_body("Error while decoding body as JSON")
    }
  }

  case route.has_body {
    False -> call_callback(route.req_body_converter.decoder(dynamic.from(Nil)))
    True -> {
      use json <- wisp.require_json(req)
      json
      |> route.req_body_converter.decoder
      |> call_callback
    }
  }
}

fn handle_result(
  handler: fn() -> Result(string_builder.StringBuilder, errors.AppError),
) -> wisp.Response {
  let result = handler()

  case result {
    Ok(res) -> wisp.json_response(res, 200)
    Error(errors.DecoderError(msg)) ->
      wisp.json_response(string_builder.from_string(msg), 400)
    Error(errors.DBError(msg)) ->
      wisp.json_response(string_builder.from_string(msg), 500)
  }
}
