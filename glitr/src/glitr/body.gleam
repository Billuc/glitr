import gleam/dynamic
import gleam/json
import gleam/result
import gleam/string_builder
import glitr/error

// pub type BodyType(body_type) {
//   EmptyBody
//   JsonBody(converter: JsonConverter(body_type))
// }

pub type BodyType {
  EmptyBody
  StringBody
  JsonBody
}

pub type BodyConverter(body_type) {
  BodyConverter(
    encoder: fn(body_type) -> string_builder.StringBuilder,
    decoder: fn(String) -> Result(body_type, error.GlitrError),
  )
}

pub opaque type RouteBody(body_type) {
  RouteBody(btype: BodyType, converter: BodyConverter(body_type))
}

pub fn empty_body() -> RouteBody(Nil) {
  RouteBody(
    EmptyBody,
    BodyConverter(
      fn(_) { string_builder.new() },
      //
      fn(_) { Ok(Nil) },
    ),
  )
}

pub fn json_body(
  encoder: fn(body_type) -> json.Json,
  decoder: fn(dynamic.Dynamic) -> Result(body_type, List(dynamic.DecodeError)),
) -> RouteBody(body_type) {
  RouteBody(
    JsonBody,
    BodyConverter(
      fn(value) { value |> encoder |> json.to_string_builder },
      //
      fn(body) {
        json.decode(from: body, using: decoder)
        |> result.map_error(fn(err) { error.JsonDecodeError(err) })
      },
    ),
  )
}

pub fn string_body(converter: BodyConverter(b)) -> RouteBody(b) {
  RouteBody(StringBody, converter)
}

pub fn encode(body: RouteBody(b), value: b) -> string_builder.StringBuilder {
  value |> body.converter.encoder
}

pub fn decode(body: RouteBody(b), value: String) -> Result(b, error.GlitrError) {
  value |> body.converter.decoder
}

pub fn get_type(body: RouteBody(_)) -> BodyType {
  body.btype
}
