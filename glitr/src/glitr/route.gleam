import gleam/http
import glitr
import glitr/utils

pub fn new() -> glitr.Route(Nil, Nil, Nil, Nil) {
  glitr.Route(
    http.Get,
    http.Http,
    "localhost",
    80,
    False,
    utils.simple_path_converter([]),
    utils.no_query_converter(),
    utils.no_body_converter(),
    utils.no_body_converter(),
  )
}

pub fn with_method(
  route: glitr.Route(p, q, b, c),
  method: http.Method,
) -> glitr.Route(p, q, b, c) {
  glitr.Route(..route, method: method)
}

pub fn with_scheme(
  route: glitr.Route(p, q, b, c),
  scheme: http.Scheme,
) -> glitr.Route(p, q, b, c) {
  glitr.Route(..route, scheme: scheme)
}

pub fn with_host(
  route: glitr.Route(p, q, b, c),
  host: String,
) -> glitr.Route(p, q, b, c) {
  glitr.Route(..route, host: host)
}

pub fn with_port(
  route: glitr.Route(p, q, b, c),
  port: Int,
) -> glitr.Route(p, q, b, c) {
  glitr.Route(..route, port: port)
}

pub fn with_has_body(
  route: glitr.Route(p, q, b, c),
  has_body: Bool,
) -> glitr.Route(p, q, b, c) {
  glitr.Route(..route, has_body: has_body)
}

pub fn with_path_converter(
  route: glitr.Route(p, q, b, c),
  path_converter: glitr.PathConverter(p2),
) -> glitr.Route(p2, q, b, c) {
  glitr.Route(
    method: route.method,
    scheme: route.scheme,
    host: route.host,
    port: route.port,
    has_body: route.has_body,
    path_converter: path_converter,
    query_converter: route.query_converter,
    req_body_converter: route.req_body_converter,
    res_body_converter: route.res_body_converter,
  )
}

pub fn with_query_converter(
  route: glitr.Route(p, q, b, c),
  query_converter: glitr.QueryConverter(q2),
) -> glitr.Route(p, q2, b, c) {
  glitr.Route(
    method: route.method,
    scheme: route.scheme,
    host: route.host,
    port: route.port,
    has_body: route.has_body,
    path_converter: route.path_converter,
    query_converter: query_converter,
    req_body_converter: route.req_body_converter,
    res_body_converter: route.res_body_converter,
  )
}

pub fn with_request_body_converter(
  route: glitr.Route(p, q, b, c),
  req_body_converter: glitr.JsonConverter(b2),
) -> glitr.Route(p, q, b2, c) {
  glitr.Route(
    method: route.method,
    scheme: route.scheme,
    host: route.host,
    port: route.port,
    has_body: route.has_body,
    path_converter: route.path_converter,
    query_converter: route.query_converter,
    req_body_converter: req_body_converter,
    res_body_converter: route.res_body_converter,
  )
}

pub fn with_response_body_converter(
  route: glitr.Route(p, q, b, c),
  res_body_converter: glitr.JsonConverter(c2),
) -> glitr.Route(p, q, b, c2) {
  glitr.Route(
    method: route.method,
    scheme: route.scheme,
    host: route.host,
    port: route.port,
    has_body: route.has_body,
    path_converter: route.path_converter,
    query_converter: route.query_converter,
    req_body_converter: route.req_body_converter,
    res_body_converter: res_body_converter,
  )
}
