import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import glitr_convert.{type GlitrType, type GlitrValue}

pub opaque type Converter(a) {
  Converter(
    decoder: fn(GlitrValue) -> Result(a, List(dynamic.DecodeError)),
    type_def: GlitrType,
  )
}

pub fn object(constructor: a) -> Converter(a) {
  Converter(fn(_) { Ok(constructor) }, glitr_convert.Object([]))
}

pub fn parameter(body: fn(t1) -> t2) -> fn(t1) -> t2 {
  body
}

pub fn field(
  converter: Converter(fn(a) -> b),
  field_name: String,
  field_type: Converter(a),
) -> Converter(b) {
  Converter(
    decoder: fn(v: GlitrValue) {
      case v {
        glitr_convert.ObjectValue(values) -> {
          let constructor = converter.decoder(v)
          let data =
            values
            |> list.key_find(field_name)
            |> result.replace_error([
              dynamic.DecodeError("Value", "None", [field_name]),
            ])
            |> result.then(field_type.decoder)

          case constructor, data {
            Ok(c), Ok(d) -> Ok(c(d))
            Error(e1), Error(e2) -> Error(list.append(e1, e2))
            _, Error(e) | Error(e), _ -> Error(e)
          }
        }
        _ -> Error([])
      }
    },
    type_def: {
      case converter.type_def {
        glitr_convert.Object(fields) ->
          glitr_convert.Object(
            list.append(fields, [#(field_name, field_type.type_def)]),
          )
        _ -> glitr_convert.Object([#(field_name, field_type.type_def)])
      }
    },
  )
}

pub fn string() -> Converter(String) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.StringValue(val) -> Ok(val)
        other ->
          Error([dynamic.DecodeError("StringValue", get_type(other), [])])
      }
    },
    glitr_convert.String,
  )
}

pub fn bool() -> Converter(Bool) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.BoolValue(val) -> Ok(val)
        other -> Error([dynamic.DecodeError("BoolValue", get_type(other), [])])
      }
    },
    glitr_convert.Bool,
  )
}

pub fn float() -> Converter(Float) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.FloatValue(val) -> Ok(val)
        other -> Error([dynamic.DecodeError("FloatValue", get_type(other), [])])
      }
    },
    glitr_convert.Float,
  )
}

pub fn int() -> Converter(Int) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.IntValue(val) -> Ok(val)
        other -> Error([dynamic.DecodeError("IntValue", get_type(other), [])])
      }
    },
    glitr_convert.Int,
  )
}

pub fn null() -> Converter(Nil) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.NullValue -> Ok(Nil)
        other -> Error([dynamic.DecodeError("NullValue", get_type(other), [])])
      }
    },
    glitr_convert.Null,
  )
}

pub fn list(of: Converter(a)) -> Converter(List(a)) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.ListValue(vals) ->
          vals
          |> list.fold(Ok([]), fn(result, val) {
            case result, of.decoder(val) {
              Ok(res), Ok(new_res) -> Ok(list.append(res, [new_res]))
              Error(errs), Error(new_errs) -> Error(list.append(errs, new_errs))
              _, Error(errs) | Error(errs), _ -> Error(errs)
            }
          })
        other -> Error([dynamic.DecodeError("ListValue", get_type(other), [])])
      }
    },
    glitr_convert.List(of.type_def),
  )
}

pub fn optional(of: Converter(a)) -> Converter(option.Option(a)) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.OptionalValue(option.None) -> Ok(option.None)
        glitr_convert.OptionalValue(option.Some(val)) ->
          val |> of.decoder |> result.map(option.Some)
        other ->
          Error([dynamic.DecodeError("OptionalValue", get_type(other), [])])
      }
    },
    glitr_convert.Optional(of.type_def),
  )
}

pub fn result(
  res: Converter(ok),
  error: Converter(err),
) -> Converter(Result(ok, err)) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.ResultValue(Ok(val)) ->
          val |> res.decoder |> result.map(Ok)
        glitr_convert.ResultValue(Error(val)) ->
          val |> error.decoder |> result.map(Error)
        other ->
          Error([dynamic.DecodeError("ResultValue", get_type(other), [])])
      }
    },
    glitr_convert.Result(res.type_def, error.type_def),
  )
}

pub fn dict(
  key: Converter(k),
  value: Converter(v),
) -> Converter(dict.Dict(k, v)) {
  Converter(
    fn(v: GlitrValue) {
      case v {
        glitr_convert.DictValue(d) ->
          d
          |> dict.to_list
          |> list.fold(Ok([]), fn(result, kv) {
            case result, key.decoder(kv.0), value.decoder(kv.1) {
              Ok(values), Ok(new_k), Ok(new_v) ->
                Ok(list.append(values, [#(new_k, new_v)]))
              Error(errs), Ok(_), Ok(_)
              | Ok(_), Ok(_), Error(errs)
              | Ok(_), Error(errs), Ok(_)
              -> Error(errs)
              Ok(_), Error(errs_1), Error(errs_2)
              | Error(errs_1), Error(errs_2), Ok(_)
              | Error(errs_1), Ok(_), Error(errs_2)
              -> Error(list.append(errs_1, errs_2))
              Error(errs), Error(errs_k), Error(errs_v) ->
                Error(list.concat([errs, errs_k, errs_v]))
            }
          })
          |> result.map(dict.from_list)
        other -> Error([dynamic.DecodeError("DictValue", get_type(other), [])])
      }
    },
    glitr_convert.Dict(key.type_def, value.type_def),
  )
}

fn get_type(val: _) -> String {
  let as_dyn = val |> dynamic.from
  as_dyn
  |> dynamic.element(0, dynamic.string)
  |> result.unwrap(as_dyn |> dynamic.classify)
}

pub fn encode(
  converter: Converter(a),
  value: a,
) -> Result(GlitrValue, List(dynamic.DecodeError)) {
  value |> dynamic.from |> glitr_convert.dynamic_decode(converter.type_def)
}

pub fn json_encode(
  converter: Converter(a),
  value: a,
) -> Result(json.Json, List(dynamic.DecodeError)) {
  use glitr_value <- result.map(converter |> encode(value))

  glitr_convert.glitr_value_encode(glitr_value)
}

pub fn decode(
  converter: Converter(a),
  value: GlitrValue,
) -> Result(a, List(dynamic.DecodeError)) {
  value |> converter.decoder
}

pub fn json_decode(
  converter: Converter(a),
  value: dynamic.Dynamic,
) -> Result(a, List(dynamic.DecodeError)) {
  value
  |> glitr_convert.json_decode(converter.type_def)
  |> result.then(converter.decoder)
}
