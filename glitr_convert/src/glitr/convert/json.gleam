import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import glitr/convert as c

/// Encode a value into the corresponding Json using the converter.  
/// If the converter isn't valid, a NullValue is returned.
pub fn json_encode(value: a, converter: c.Converter(a)) -> json.Json {
  value |> c.encode(converter) |> encode_value
}

/// Decode a Json value using the provided converter.
pub fn json_decode(
  converter: c.Converter(a),
) -> fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError)) {
  fn(value) {
    value
    |> decode_value(c.type_def(converter))
    |> result.then(c.decode(converter))
  }
}

/// Encode a GlitrValue into its corresponding JSON representation.  
/// This is not meant to be used directly !  
/// It is better to use converters.
pub fn encode_value(val: c.GlitrValue) -> json.Json {
  case val {
    c.StringValue(v) -> json.string(v)
    c.BoolValue(v) -> json.bool(v)
    c.FloatValue(v) -> json.float(v)
    c.IntValue(v) -> json.int(v)
    c.ListValue(vals) -> json.array(vals, encode_value)
    c.DictValue(v) ->
      json.array(v |> dict.to_list, fn(keyval) {
        json.array([keyval.0, keyval.1], encode_value)
      })
    c.ObjectValue(v) ->
      json.object(list.map(v, fn(f) { #(f.0, encode_value(f.1)) }))
    c.OptionalValue(v) -> json.nullable(v, encode_value)
    c.ResultValue(v) ->
      case v {
        Ok(res) ->
          json.object([
            #("type", json.string("ok")),
            #("value", encode_value(res)),
          ])
        Error(err) ->
          json.object([
            #("type", json.string("error")),
            #("value", encode_value(err)),
          ])
      }
    c.EnumValue(variant, v) ->
      json.object([
        #("variant", json.string(variant)),
        #("value", encode_value(v)),
      ])
    _ -> json.null()
  }
}

/// Decode a JSON value using the specified GlitrType as the shape of the data.  
/// Returns the corresponding GlitrValue representation.
/// This isn't meant to be used directly !
pub fn decode_value(
  of: c.GlitrType,
) -> fn(dynamic.Dynamic) -> Result(c.GlitrValue, List(dynamic.DecodeError)) {
  case of {
    c.String -> fn(val) { val |> dynamic.string() |> result.map(c.StringValue) }
    c.Bool -> fn(val) { val |> dynamic.bool() |> result.map(c.BoolValue) }
    c.Float -> fn(val) { val |> dynamic.float() |> result.map(c.FloatValue) }
    c.Int -> fn(val) { val |> dynamic.int() |> result.map(c.IntValue) }
    c.List(el) -> fn(val) {
      val
      |> dynamic.list(dynamic.dynamic)
      |> result.then(fn(val_list) {
        list.fold(val_list, Ok([]), fn(result, list_el) {
          case result, list_el |> decode_value(el) {
            Ok(result_list), Ok(jval) -> Ok([jval, ..result_list])
            Ok(_), Error(errs) | Error(errs), Ok(_) -> Error(errs)
            Error(errs), Error(new_errs) -> Error(list.append(errs, new_errs))
          }
        })
      })
      |> result.map(list.reverse)
      |> result.map(c.ListValue)
    }
    c.Dict(k, v) -> fn(val) {
      val
      |> dynamic.list(
        of: dynamic.list(of: dynamic.any([decode_value(k), decode_value(v)])),
      )
      |> result.then(list.fold(
        _,
        Ok([]),
        fn(result, el) {
          case result, el {
            Ok(vals), [first, second, ..] -> Ok([#(first, second), ..vals])
            Ok(_), _ -> Error([dynamic.DecodeError("2 elements", "0 or 1", [])])
            // TODO: better path
            Error(errs), [_, _, ..] -> Error(errs)
            Error(errs), _ ->
              Error([dynamic.DecodeError("2 elements", "0 or 1", []), ..errs])
          }
        },
      ))
      |> result.map(dict.from_list)
      |> result.map(c.DictValue)
    }
    c.Object(fields) -> fn(val) {
      list.fold(fields, Ok([]), fn(result, f) {
        case result, val |> dynamic.field(f.0, decode_value(f.1)) {
          Ok(field_list), Ok(jval) -> Ok([#(f.0, jval), ..field_list])
          Ok(_), Error(errs) | Error(errs), Ok(_) -> Error(errs)
          Error(errs), Error(new_errs) -> Error(list.append(errs, new_errs))
        }
      })
      |> result.map(list.reverse)
      |> result.map(c.ObjectValue)
    }
    c.Optional(of) -> fn(val) {
      val |> dynamic.optional(decode_value(of)) |> result.map(c.OptionalValue)
    }
    c.Result(res, err) -> fn(val) {
      use type_val <- result.try(val |> dynamic.field("type", dynamic.string))

      case type_val {
        "ok" ->
          val
          |> dynamic.field("value", decode_value(res))
          |> result.map(Ok)
          |> result.map(c.ResultValue)
        "error" ->
          val
          |> dynamic.field("value", decode_value(err))
          |> result.map(Error)
          |> result.map(c.ResultValue)
        other ->
          Error([dynamic.DecodeError("'ok' or 'error'", other, ["type"])])
        // TODO : better path
      }
    }
    c.Enum(variants) -> fn(val) {
      use variant_name <- result.try(
        val |> dynamic.field("variant", dynamic.string),
      )
      use variant_def <- result.try(
        list.key_find(variants, variant_name)
        |> result.replace_error([
          dynamic.DecodeError(
            "One of: "
              <> variants |> list.map(fn(v) { v.0 }) |> string.join("/"),
            variant_name,
            ["variant"],
          ),
        ]),
      )
      use variant_value <- result.try(
        val
        |> dynamic.field("value", dynamic.dynamic)
        |> result.then(decode_value(variant_def)),
      )

      Ok(c.EnumValue(variant_name, variant_value))
    }
    _ -> fn(_val) { Ok(c.NullValue) }
  }
}
