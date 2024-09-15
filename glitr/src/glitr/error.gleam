import gleam/json

pub type GlitrError {
  RouteError(msg: String)
  JsonDecodeError(err: json.DecodeError)
}
