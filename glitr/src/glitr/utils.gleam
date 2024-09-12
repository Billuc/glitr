import gleam/bool
import gleam/http/request
import gleam/json
import gleam/list
import gleam/string
import glitr

pub fn simple_path_converter(root: List(String)) -> glitr.PathConverter(Nil) {
  glitr.PathConverter(fn(_) { root }, fn(segs) {
    use <- bool.guard(segs == root, Ok(Nil))
    Error(Nil)
  })
}

pub fn id_path_converter(root: List(String)) -> glitr.PathConverter(String) {
  glitr.PathConverter(fn(id) { list.append(root, [id]) }, fn(segs) {
    let reverse_root = list.reverse(root)
    case list.reverse(segs) {
      [id, ..rest] if rest == reverse_root -> Ok(id)
      _ -> Error(Nil)
    }
  })
}

pub fn no_body_converter() -> glitr.JsonConverter(Nil) {
  glitr.JsonConverter(fn(_) { json.null() }, fn(_) { Ok(Nil) })
}

pub fn to_request(
  route: glitr.Route(p, rqb, rsb),
  path: p,
  body: rqb,
) -> request.Request(String) {
  let req =
    request.new()
    |> request.set_method(route.method)
    |> request.set_scheme(route.scheme)
    |> request.set_host(route.host)
    |> request.set_port(route.port)
    |> request.set_path(
      path |> route.path_converter.encoder |> string.join("/"),
    )

  case route.has_body {
    True ->
      req
      |> request.set_body(
        body |> route.req_body_converter.encoder |> json.to_string,
      )
      |> request.set_header("Content-Type", "application/json")
    False -> req
  }
}
