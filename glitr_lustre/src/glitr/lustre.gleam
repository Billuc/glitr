//// This module helps to make the bridge between glitr Routes and lustre

import gleam/http
import gleam/http/request
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_builder
import glitr
import glitr/body
import glitr/error
import glitr/path
import glitr/query
import glitr/route
import lustre/effect
import lustre_http

pub opaque type RequestFactory {
  /// A request factory helps you create requests automatically from routes.  
  /// It contains data on the way to reach the backend (scheme, host and port).
  /// It is meant to be reusable as usually one frontend connects mainly to one backend
  RequestFactory(scheme: http.Scheme, host: String, port: Int)
}

/// Create a new default factory  
/// By default, it points to "http://localhost:80"
pub fn create_factory() -> RequestFactory {
  RequestFactory(http.Http, "localhost", 80)
}

/// Changes the scheme of a RequestFactory  
/// Also sets the port to the default for the selected scheme (80 for http and 443 for https)
pub fn with_scheme(
  factory: RequestFactory,
  scheme: http.Scheme,
) -> RequestFactory {
  case scheme {
    http.Http -> RequestFactory(http.Http, factory.host, 80)
    http.Https -> RequestFactory(http.Https, factory.host, 443)
  }
}

/// Changes the host of a RequestFactory
pub fn with_host(factory: RequestFactory, host: String) -> RequestFactory {
  RequestFactory(..factory, host: host)
}

/// Changes the port of a RequestFactory
pub fn with_port(factory: RequestFactory, port: Int) -> RequestFactory {
  RequestFactory(..factory, port: port)
}

/// Create a RouteRequest given a RequestFactory and a Route
pub fn for_route(
  factory: RequestFactory,
  route: route.Route(p, q, b, c),
) -> RouteRequest(p, q, b, c) {
  RouteRequest(
    route,
    factory.scheme,
    factory.host,
    factory.port,
    None,
    None,
    None,
  )
}

/// A RouteRequest contains the data required to send a request to a backend  
/// This data contains a route, all the data from the factory that created the request
/// as well as path, query and body data that will have to be provided
pub opaque type RouteRequest(p, q, b, c) {
  RouteRequest(
    route: route.Route(p, q, b, c),
    scheme: http.Scheme,
    host: String,
    port: Int,
    path_opt: Option(p),
    query_opt: Option(q),
    body_opt: Option(b),
  )
}

/// Set the path, query and body data all at the same time
pub fn with_options(
  request: RouteRequest(p, q, b, _),
  options: glitr.RouteOptions(p, q, b),
) -> RouteRequest(p, q, b, _) {
  RouteRequest(
    ..request,
    path_opt: Some(options.path),
    query_opt: Some(options.query),
    body_opt: Some(options.body),
  )
}

/// Set the path data for this request  
pub fn with_path(
  request: RouteRequest(p, _, _, _),
  path: p,
) -> RouteRequest(p, _, _, _) {
  RouteRequest(..request, path_opt: Some(path))
}

/// Set the query data for this request
pub fn with_query(
  request: RouteRequest(_, q, _, _),
  query: q,
) -> RouteRequest(_, q, _, _) {
  RouteRequest(..request, query_opt: Some(query))
}

/// Set the body data for this request
pub fn with_body(
  request: RouteRequest(_, _, b, _),
  body: b,
) -> RouteRequest(_, _, b, _) {
  RouteRequest(..request, body_opt: Some(body))
}

/// Send a RouteRequest and handle the result  
/// Uses lustre_http under the hood to send the result, catch the response and transform the data
pub fn send(
  rreq: RouteRequest(p, q, b, c),
  as_msg: fn(Result(c, lustre_http.HttpError)) -> msg,
  on_error: fn(String) -> effect.Effect(msg),
) -> effect.Effect(msg) {
  let req =
    request.new()
    |> request.set_method(rreq.route.method)

  use req <- add_path(req, rreq, on_error)
  use req <- add_query(req, rreq, on_error)
  use req <- add_body(req, rreq, on_error)

  let req =
    req
    |> request.set_scheme(rreq.scheme)
    |> request.set_host(rreq.host)
    |> request.set_port(rreq.port)

  req
  |> lustre_http.send(
    lustre_http.expect_text(fn(body) {
      body
      |> result.then(fn(value) {
        rreq.route.res_body
        |> body.decode(value)
        |> result.map_error(glitr_to_http_error)
      })
      |> as_msg
    }),
  )
}

/// Set the path of the request based on data stored in the RouteRequest  
/// It is meant to be used with use and provides the request with the path set.
/// It will call on_error if no path data is provided.
fn add_path(
  req: request.Request(String),
  rreq: RouteRequest(p, q, b, c),
  on_error: fn(String) -> effect.Effect(msg),
  then: fn(request.Request(String)) -> effect.Effect(msg),
) -> effect.Effect(msg) {
  case rreq.route.path |> path.get_type, rreq.path_opt {
    path.ComplexPath, None ->
      on_error("Path option is missing, please call with_path before send")
    path.ComplexPath, Some(path) ->
      then(
        req
        |> request.set_path(
          rreq.route.path |> path.encode(path) |> string.join("/"),
        ),
      )
    path.StaticPath(root), _ ->
      then(req |> request.set_path(root |> string.join("/")))
  }
}

/// Set the query of the request based on data stored in the RouteRequest  
/// It is meant to be used with use and provides the request with the query set.
/// It will call on_error if no query data is provided and is required.
fn add_query(
  req: request.Request(String),
  rreq: RouteRequest(p, q, b, c),
  on_error: fn(String) -> effect.Effect(msg),
  then: fn(request.Request(String)) -> effect.Effect(msg),
) -> effect.Effect(msg) {
  case rreq.route.query |> query.get_type, rreq.query_opt {
    query.ComplexQuery, None ->
      on_error("Query option is missing, please call with_query before send")
    query.EmptyQuery, _ -> then(req)
    query.ComplexQuery, Some(query) ->
      then(req |> request.set_query(rreq.route.query |> query.encode(query)))
  }
}

/// Set the body of the request based on data stored in the RouteRequest  
/// It is meant to be used with use and provides the request with the body set.
/// It will call on_error if no body data is provided and is required.
fn add_body(
  req: request.Request(String),
  rreq: RouteRequest(p, q, b, c),
  on_error: fn(String) -> effect.Effect(msg),
  then: fn(request.Request(String)) -> effect.Effect(msg),
) -> effect.Effect(msg) {
  case rreq.route.req_body |> body.get_type, rreq.body_opt {
    body.JsonBody, None | body.StringBody, None ->
      on_error("Body option is missing, please call with_body before send")
    body.EmptyBody, _ -> then(req)
    body.JsonBody, Some(body) ->
      then(
        req
        |> request.set_body(
          rreq.route.req_body |> body.encode(body) |> string_builder.to_string,
        )
        |> request.set_header("Content-Type", "application/json"),
      )
    body.StringBody, Some(body) ->
      then(
        req
        |> request.set_body(
          rreq.route.req_body |> body.encode(body) |> string_builder.to_string,
        ),
      )
  }
}

/// Mapper function between GlitrError and HttpError
fn glitr_to_http_error(err: error.GlitrError) -> lustre_http.HttpError {
  case err {
    error.RouteError(msg) -> lustre_http.OtherError(500, msg)
    error.JsonDecodeError(json_err) -> lustre_http.JsonError(json_err)
  }
}
