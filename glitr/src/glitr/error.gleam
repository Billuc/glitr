import gleam/json

/// Errors that can occur in Glitr code
pub type GlitrError {
  RouteError(msg: String)
  JsonDecodeError(err: json.DecodeError)
}
