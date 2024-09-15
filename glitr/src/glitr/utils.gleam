import gleam/http/request
import gleam/string
import gleam/string_builder
import glitr/body
import glitr/path
import glitr/query
import glitr/route

pub fn to_request(
  route: route.Route(p, q, rqb, rsb),
  path: p,
  query: q,
  body: rqb,
) -> request.Request(String) {
  let req =
    request.new()
    |> request.set_method(route.method)
    |> request.set_path(route.path |> path.encode(path) |> string.join("/"))
    |> request.set_query(route.query |> query.encode(query))
    |> request.set_body(
      route.req_body |> body.encode(body) |> string_builder.to_string,
    )

  let req = case route.req_body |> body.get_type {
    body.JsonBody ->
      req
      |> request.set_header("Content-Type", "application/json")
    _ -> req
  }

  req
}
