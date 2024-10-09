import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import glitr_convert as g
import glitr_convert/converters as c

/// Encode a value into the corresponding Json using the converter.  
/// If the converter isn't valid, a NullValue is returned.
pub fn json_encode(value: a, converter: c.Converter(a)) -> json.Json {
  value |> c.encode(converter) |> encode
}

/// Decode a Json value using the provided converter.
pub fn json_decode(
  converter: c.Converter(a),
) -> fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError)) {
  fn(value) {
    value
    |> decode(c.type_def(converter))
    |> result.then(c.decode(converter))
  }
}

/// Encode a GlitrValue into its corresponding JSON representation.  
/// This is not meant to be used directly !  
/// It is better to use converters.
fn encode(val: g.GlitrValue) -> json.Json {
  case val {
    g.StringValue(v) -> json.string(v)
    g.BoolValue(v) -> json.bool(v)
    g.FloatValue(v) -> json.float(v)
    g.IntValue(v) -> json.int(v)
    g.ListValue(vals) -> json.array(vals, encode)
    g.DictValue(v) ->
      json.array(v |> dict.to_list, fn(keyval) {
        json.array([keyval.0, keyval.1], encode)
      })
    g.ObjectValue(v) -> json.object(list.map(v, fn(f) { #(f.0, encode(f.1)) }))
    g.OptionalValue(v) -> json.nullable(v, encode)
    g.ResultValue(v) ->
      case v {
        Ok(res) ->
          json.object([#("type", json.string("ok")), #("value", encode(res))])
        Error(err) ->
          json.object([#("type", json.string("error")), #("value", encode(err))])
      }
    g.EnumValue(variant, v) ->
      json.object([#("variant", json.string(variant)), #("value", encode(v))])
    _ -> json.null()
  }
}

/// Decode a JSON value using the specified GlitrType as the shape of the data.  
/// Returns the corresponding GlitrValue representation.
/// This isn't meant to be used directly !
fn decode(
  of: g.GlitrType,
) -> fn(dynamic.Dynamic) -> Result(g.GlitrValue, List(dynamic.DecodeError)) {
  case of {
    g.String -> fn(val) { val |> dynamic.string() |> result.map(g.StringValue) }
    g.Bool -> fn(val) { val |> dynamic.bool() |> result.map(g.BoolValue) }
    g.Float -> fn(val) { val |> dynamic.float() |> result.map(g.FloatValue) }
    g.Int -> fn(val) { val |> dynamic.int() |> result.map(g.IntValue) }
    g.List(el) -> fn(val) {
      val
      |> dynamic.list(dynamic.dynamic)
      |> result.then(fn(val_list) {
        list.fold(val_list, Ok([]), fn(result, list_el) {
          case result {
            Ok(result_list) ->
              case list_el |> decode(el) {
                Error(errs) -> Error(errs)
                Ok(jval) -> Ok([jval, ..result_list])
              }
            Error(errs) ->
              case val |> decode(el) {
                Error(new_errs) -> Error(list.append(errs, new_errs))
                Ok(_) -> Error(errs)
              }
          }
        })
      })
      |> result.map(list.reverse)
      |> result.map(g.ListValue)
    }
    g.Dict(k, v) -> fn(val) {
      val
      |> dynamic.list(of: dynamic.list(of: dynamic.any([decode(k), decode(v)])))
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
      |> result.map(g.DictValue)
    }
    g.Object(fields) -> fn(val) {
      list.fold(fields, Ok([]), fn(result, f) {
        case result {
          Ok(field_list) ->
            case val |> dynamic.field(f.0, decode(f.1)) {
              Error(errs) -> Error(errs)
              Ok(jval) -> Ok([#(f.0, jval), ..field_list])
            }
          Error(errs) ->
            case val |> dynamic.field(f.0, decode(f.1)) {
              Error(new_errs) -> Error(list.append(errs, new_errs))
              Ok(_) -> Error(errs)
            }
        }
      })
      |> result.map(list.reverse)
      |> result.map(g.ObjectValue)
    }
    g.Optional(of) -> fn(val) {
      val |> dynamic.optional(decode(of)) |> result.map(g.OptionalValue)
    }
    g.Result(res, err) -> fn(val) {
      use type_val <- result.try(val |> dynamic.field("type", dynamic.string))

      case type_val {
        "ok" ->
          val
          |> dynamic.field("value", decode(res))
          |> result.map(Ok)
          |> result.map(g.ResultValue)
        "error" ->
          val
          |> dynamic.field("value", decode(err))
          |> result.map(Error)
          |> result.map(g.ResultValue)
        other -> Error([dynamic.DecodeError("ok or error", other, ["type"])])
        // TODO : better path
      }
    }
    g.Enum(variants) -> fn(val) {
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
        |> result.then(decode(variant_def)),
      )

      Ok(g.EnumValue(variant_name, variant_value))
    }
    _ -> fn(_val) { Ok(g.NullValue) }
  }
}
