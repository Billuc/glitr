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

pub type Route(path_type, req_body_type, res_body_type) {
  Route(
    method: http.Method,
    scheme: http.Scheme,
    host: String,
    port: Int,
    has_body: Bool,
    path_converter: PathConverter(path_type),
    req_body_converter: JsonConverter(req_body_type),
    res_body_converter: JsonConverter(res_body_type),
  )
}
