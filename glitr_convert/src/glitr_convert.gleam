import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string

pub type GlitrType {
  String
  Bool
  Float
  Int
  Null
  List(of: GlitrType)
  Dict(key: GlitrType, value: GlitrType)
  Object(fields: List(#(String, GlitrType)))
  Optional(of: GlitrType)
  Result(result: GlitrType, error: GlitrType)
  Enum(variants: List(#(String, GlitrType)))
  // Maybe add BitArray
}

pub type GlitrValue {
  StringValue(value: String)
  BoolValue(value: Bool)
  FloatValue(value: Float)
  IntValue(value: Int)
  NullValue
  ListValue(value: List(GlitrValue))
  DictValue(value: dict.Dict(GlitrValue, GlitrValue))
  ObjectValue(value: List(#(String, GlitrValue)))
  OptionalValue(value: option.Option(GlitrValue))
  ResultValue(value: Result(GlitrValue, GlitrValue))
  EnumValue(variant: String, value: GlitrValue)
}

pub fn json_encode(val: GlitrValue) -> json.Json {
  case val {
    StringValue(v) -> json.string(v)
    BoolValue(v) -> json.bool(v)
    FloatValue(v) -> json.float(v)
    IntValue(v) -> json.int(v)
    ListValue(vals) -> json.array(vals, json_encode)
    DictValue(v) ->
      json.array(v |> dict.to_list, fn(keyval) {
        json.array([keyval.0, keyval.1], json_encode)
      })
    ObjectValue(v) ->
      json.object(list.map(v, fn(f) { #(f.0, json_encode(f.1)) }))
    OptionalValue(v) -> json.nullable(v, json_encode)
    ResultValue(v) ->
      case v {
        Ok(res) ->
          json.object([
            #("type", json.string("ok")),
            #("value", json_encode(res)),
          ])
        Error(err) ->
          json.object([
            #("type", json.string("error")),
            #("value", json_encode(err)),
          ])
      }
    EnumValue(variant, v) ->
      json.object([
        #("variant", json.string(variant)),
        #("value", json_encode(v)),
      ])
    _ -> json.null()
  }
}

pub fn json_decode(
  of: GlitrType,
) -> fn(dynamic.Dynamic) -> Result(GlitrValue, List(dynamic.DecodeError)) {
  case of {
    String -> fn(val) { val |> dynamic.string() |> result.map(StringValue) }
    Bool -> fn(val) { val |> dynamic.bool() |> result.map(BoolValue) }
    Float -> fn(val) { val |> dynamic.float() |> result.map(FloatValue) }
    Int -> fn(val) { val |> dynamic.int() |> result.map(IntValue) }
    List(el) -> fn(val) {
      val
      |> dynamic.list(dynamic.dynamic)
      |> result.then(fn(val_list) {
        list.fold(val_list, Ok([]), fn(result, list_el) {
          case result {
            Ok(result_list) ->
              case list_el |> json_decode(el) {
                Error(errs) -> Error(errs)
                Ok(jval) -> Ok([jval, ..result_list])
              }
            Error(errs) ->
              case val |> json_decode(el) {
                Error(new_errs) -> Error(list.append(errs, new_errs))
                Ok(_) -> Error(errs)
              }
          }
        })
      })
      |> result.map(list.reverse)
      |> result.map(ListValue)
    }
    Dict(k, v) -> fn(val) {
      val
      |> dynamic.list(
        of: dynamic.list(of: dynamic.any([json_decode(k), json_decode(v)])),
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
      |> result.map(DictValue)
    }
    Object(fields) -> fn(val) {
      list.fold(fields, Ok([]), fn(result, f) {
        case result {
          Ok(field_list) ->
            case val |> dynamic.field(f.0, json_decode(f.1)) {
              Error(errs) -> Error(errs)
              Ok(jval) -> Ok([#(f.0, jval), ..field_list])
            }
          Error(errs) ->
            case val |> dynamic.field(f.0, json_decode(f.1)) {
              Error(new_errs) -> Error(list.append(errs, new_errs))
              Ok(_) -> Error(errs)
            }
        }
      })
      |> result.map(list.reverse)
      |> result.map(ObjectValue)
    }
    Optional(of) -> fn(val) {
      val |> dynamic.optional(json_decode(of)) |> result.map(OptionalValue)
    }
    Result(res, err) -> fn(val) {
      use type_val <- result.try(val |> dynamic.field("type", dynamic.string))

      case type_val {
        "ok" ->
          val
          |> dynamic.field("value", json_decode(res))
          |> result.map(Ok)
          |> result.map(ResultValue)
        "error" ->
          val
          |> dynamic.field("value", json_decode(err))
          |> result.map(Error)
          |> result.map(ResultValue)
        other -> Error([dynamic.DecodeError("ok or error", other, ["type"])])
        // TODO : better path
      }
    }
    Enum(variants) -> fn(val) {
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
        |> result.then(json_decode(variant_def)),
      )

      Ok(EnumValue(variant_name, variant_value))
    }
    _ -> fn(_val) { Ok(NullValue) }
  }
}
