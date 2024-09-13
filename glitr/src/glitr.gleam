import gleam/dynamic
import gleam/http
import gleam/json

pub type JsonEncoder(a) =
  fn(a) -> json.Json

pub type JsonDecoder(a) =
  fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError))

pub type JsonConverter(a) {
  JsonConverter(encoder: JsonEncoder(a), decoder: JsonDecoder(a))
}

pub type PathEncoder(a) =
  fn(a) -> List(String)

pub type PathDecoder(a) =
  fn(List(String)) -> Result(a, Nil)

pub type PathConverter(a) {
  PathConverter(encoder: PathEncoder(a), decoder: PathDecoder(a))
}

pub type QueryEncoder(a) =
  fn(a) -> List(#(String, String))

pub type QueryDecoder(a) =
  fn(List(#(String, String))) -> Result(a, Nil)

pub type QueryConverter(a) {
  QueryConverter(encoder: QueryEncoder(a), decoder: QueryDecoder(a))
}

pub type Route(path_type, query_type, req_body_type, res_body_type) {
  Route(
    method: http.Method,
    scheme: http.Scheme,
    host: String,
    port: Int,
    has_body: Bool,
    path_converter: PathConverter(path_type),
    query_converter: QueryConverter(query_type),
    req_body_converter: JsonConverter(req_body_type),
    res_body_converter: JsonConverter(res_body_type),
  )
}

pub type RouteOptions(p, q, b) {
  RouteOptions(path: p, query: q, body: b)
}
