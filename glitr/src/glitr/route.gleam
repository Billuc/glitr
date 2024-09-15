//// This module exports the Route type and builder functions.  
//// Routes correspond to endpoints on a backend that will be called from a frontend.
//// They are defined by a method, a path, a query and request/response bodies.

import gleam/http
import glitr/body
import glitr/path
import glitr/query

/// The Route type  
/// Routes should be built using the builder functions
pub type Route(path_type, query_type, req_body_type, res_body_type) {
  Route(
    method: http.Method,
    path: path.RoutePath(path_type),
    query: query.RouteQuery(query_type),
    req_body: body.RouteBody(req_body_type),
    res_body: body.RouteBody(res_body_type),
  )
}

/// Create a new Route  
/// By default the method is GET and the path, query and bodies are empty
pub fn new() -> Route(Nil, Nil, Nil, Nil) {
  Route(
    http.Get,
    path.static_path([]),
    query.empty_query(),
    body.empty_body(),
    body.empty_body(),
  )
}

/// Change the method of a Route
pub fn with_method(
  route: Route(p, q, b, c),
  method: http.Method,
) -> Route(p, q, b, c) {
  Route(..route, method: method)
}

/// Change the path of a Route
pub fn with_path(
  route: Route(p, q, b, c),
  path: path.RoutePath(p2),
) -> Route(p2, q, b, c) {
  Route(
    method: route.method,
    path: path,
    query: route.query,
    req_body: route.req_body,
    res_body: route.res_body,
  )
}

/// Change the query of a Route
pub fn with_query(
  route: Route(p, q, b, c),
  query: query.RouteQuery(q2),
) -> Route(p, q2, b, c) {
  Route(
    method: route.method,
    path: route.path,
    query: query,
    req_body: route.req_body,
    res_body: route.res_body,
  )
}

/// Change the request body of a Route
pub fn with_request_body(
  route: Route(p, q, b, c),
  req_body: body.RouteBody(b2),
) -> Route(p, q, b2, c) {
  Route(
    method: route.method,
    path: route.path,
    query: route.query,
    req_body: req_body,
    res_body: route.res_body,
  )
}

/// Change the response body of a Route
pub fn with_response_body(
  route: Route(p, q, b, c),
  res_body: body.RouteBody(c2),
) -> Route(p, q, b, c2) {
  Route(
    method: route.method,
    path: route.path,
    query: route.query,
    req_body: route.req_body,
    res_body: res_body,
  )
}
