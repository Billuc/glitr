import gleam/option
import glitr
import glitr/utils
import lustre/effect
import lustre_http

pub fn send_to_route(
  route: glitr.Route(p, q, req_b, res_b),
  path: p,
  query: q,
  body: req_b,
  as_msg: fn(Result(res_b, lustre_http.HttpError)) -> msg,
) -> effect.Effect(msg) {
  lustre_http.send(
    route |> utils.to_request(path, query, body),
    lustre_http.expect_json(route.res_body_converter.decoder, as_msg),
  )
}

pub type RouteRequest(p, q, b, c, msg) {
  RouteRequest(
    route: glitr.Route(p, q, b, c),
    options: option.Option(glitr.RouteOptions(p, q, b)),
    as_msg: fn(Result(c, lustre_http.HttpError)) -> msg,
  )
}

pub fn to_route_request(
  route: glitr.Route(p, q, b, c),
) -> RouteRequest(p, q, b, c, _) {
  RouteRequest(route, option.None, fn(_) { Nil })
}

pub fn with_options(
  request: RouteRequest(p, q, b, _, _),
  options: glitr.RouteOptions(p, q, b),
) -> RouteRequest(p, q, b, _, _) {
  RouteRequest(request.route, option.Some(options), request.as_msg)
}

pub fn with_msg(
  request: RouteRequest(_, _, _, c, msg),
  as_msg: fn(Result(c, lustre_http.HttpError)) -> msg,
) {
  RouteRequest(request.route, request.options, as_msg)
}

pub fn send(
  request: RouteRequest(p, q, b, c, msg),
  on_error: fn(String) -> effect.Effect(msg),
) -> effect.Effect(msg) {
  case request.options {
    option.None -> on_error("Please provide options before sending the request")
    option.Some(opts) ->
      request.route
      |> utils.to_request(opts.path, opts.query, opts.body)
      |> lustre_http.send(lustre_http.expect_json(
        request.route.res_body_converter.decoder,
        request.as_msg,
      ))
  }
}
