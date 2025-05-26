import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import glitr/convert as c

/// Encode a value into the corresponding Json using the converter.  
/// If the converter isn't valid, a NullValue is returned.
pub fn json_encode(value: a, converter: c.Converter(a)) -> json.Json {
  value |> c.encode(converter) |> encode_value
}

/// Decode a Json value using the provided converter.
pub fn json_decode(conv: c.Converter(a)) -> decode.Decoder(a) {
  let zero = c.default_value(conv)

  decode.then(decode_value(c.type_def(conv)), fn(glitr_val) {
    case c.decode(conv)(glitr_val) {
      Ok(v) -> decode.success(v)
      Error(_es) -> decode.failure(zero, "Unable to decode GlitrValue")
    }
  })
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
pub fn decode_value(of: c.GlitrType) -> decode.Decoder(c.GlitrValue) {
  case of {
    c.String -> decode.map(decode.string, c.StringValue)
    c.Bool -> decode.map(decode.bool, c.BoolValue)
    c.Float -> decode.map(decode.float, c.FloatValue)
    c.Int -> decode.map(decode.int, c.IntValue)
    c.List(el) -> decode_list(el)
    c.Dict(k, v) -> decode_dict(k, v)
    c.Object(fs) -> decode_object(fs)
    c.Optional(t) -> decode_optional(t)
    c.Result(ok, err) -> decode_result(ok, err)
    c.Enum(vars) -> decode_enum(vars)
    // fallback for unknown type (should rarely happen)
    _ -> decode.failure(c.NullValue, "Unsupported GlitrType")
  }
}

fn decode_list(el: c.GlitrType) -> decode.Decoder(c.GlitrValue) {
  // Decode a list of dynamics, then map each through decode_value(el)
  decode.list(decode_value(el))
  |> decode.map(c.ListValue)
}

pub fn decode_dict(
  k: c.GlitrType,
  v: c.GlitrType,
) -> decode.Decoder(c.GlitrValue) {
  decode.list(decode.list(decode.dynamic))
  |> decode.then(fn(list_of_pairs) {
    // Map and check each sublist
    let result =
      list.fold(list_of_pairs, Ok([]), fn(acc_result, el) {
        case acc_result {
          Error(errs_acc) -> Error(errs_acc)
          Ok(accum) ->
            case el {
              [key_dyn, val_dyn] ->
                case
                  decode.run(key_dyn, decode_value(k)),
                  decode.run(val_dyn, decode_value(v))
                {
                  Ok(key), Ok(val) -> Ok([#(key, val), ..accum])
                  Error(errs_k), Error(errs_v) ->
                    Error(list.append(errs_k, errs_v))
                  Error(errs), _ -> Error(errs)
                  _, Error(errs) -> Error(errs)
                }
              _ ->
                Error([decode.DecodeError("2 elements", "not a tuple of 2", [])])
            }
        }
      })
      |> result.map(list.reverse)
    // Now wrap as a decoder result:
    case result {
      Ok(pairs) -> decode.success(c.DictValue(dict.from_list(pairs)))
      Error(_errs) -> decode.failure(c.DictValue(dict.new()), "Dict: errors")
      // collapse_errors? or propagate somehow
    }
  })
}

fn build_object_decoder(
  fields: List(#(String, c.GlitrType)),
  accum: List(#(String, c.GlitrValue)),
) -> decode.Decoder(List(#(String, c.GlitrValue))) {
  case fields {
    [] -> decode.success(list.reverse(accum))
    [#(field_name, field_type), ..rest] ->
      decode.field(field_name, decode_value(field_type), fn(field_val) {
        build_object_decoder(rest, [#(field_name, field_val), ..accum])
      })
  }
}

// Public entrypoint
pub fn decode_object(
  fields: List(#(String, c.GlitrType)),
) -> decode.Decoder(c.GlitrValue) {
  build_object_decoder(fields, [])
  |> decode.map(c.ObjectValue)
}

pub fn decode_optional(t: c.GlitrType) -> decode.Decoder(c.GlitrValue) {
  decode.optional(decode_value(t))
  |> decode.map(c.OptionalValue)
}

pub fn decode_result(
  ok: c.GlitrType,
  err: c.GlitrType,
) -> decode.Decoder(c.GlitrValue) {
  // Compose the decoder with Gleam's "do-notation"
  decode.field("type", decode.string, fn(result_type) {
    case result_type {
      "ok" ->
        decode.field("value", decode_value(ok), fn(val) {
          decode.success(c.ResultValue(Ok(val)))
        })
      "error" ->
        decode.field("value", decode_value(err), fn(val) {
          decode.success(c.ResultValue(Error(val)))
        })
      other ->
        decode.failure(
          c.NullValue,
          "'type' must be 'ok' or 'error', found: " <> other,
        )
    }
  })
}

pub fn decode_enum(
  variants: List(#(String, c.GlitrType)),
) -> decode.Decoder(c.GlitrValue) {
  // 1. Decode the "variant" tag
  decode.field("variant", decode.string, fn(variant_name) {
    // 2. Look up the tag in the compile-time list
    case list.key_find(variants, variant_name) {
      Ok(var_type) ->
        // 3. Decode the corresponding "value" field
        decode.field("value", decode_value(var_type), fn(payload) {
          decode.success(c.EnumValue(variant_name, payload))
        })
      Error(_) ->
        decode.failure(
          c.NullValue,
          "Unknown enum variant: \"" <> variant_name <> "\"",
        )
    }
  })
}
