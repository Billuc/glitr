import cake/insert as i
import cake/select as s
import cake/update as u
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import glitr/convert as c
import glitr/convert/json as j

/// Sets the columns and values of the Insert using the converter and the provided values.
/// If the converter isn't an Object converter, the value is left unchanged.
/// This is because we don't have information about the fields/columns names otherwise.
pub fn cake_insert(
  value: i.Insert(a),
  converter: c.Converter(a),
  values: List(a),
) -> i.Insert(a) {
  case converter |> c.type_def {
    c.Object(fields) -> {
      value
      |> i.columns(list.map(fields, fn(f) { f.0 }))
      |> i.source_records(values, fn(v) {
        v |> c.encode(converter) |> encode_insert
      })
    }
    _ -> {
      io.println_error("Cannot insert non object values")
      value
    }
  }
}

/// Sets the column sets of the Update using the converter and the provided value.
/// If the converter isn't an Object converter, the value is left unchanged.
/// This is because we don't have information about the fields/columns names otherwise.
pub fn cake_update(
  value: u.Update(a),
  converter: c.Converter(a),
  update: a,
) -> u.Update(a) {
  case update |> c.encode(converter) {
    c.ObjectValue(fields) -> {
      value |> u.sets(fields |> list.map(encode_update))
    }
    _ -> {
      io.println_error("Cannot update non object values")
      value
    }
  }
}

/// Sets the selected colums of the Select using the converter.
/// If the converter isn't an Object converter, the value is left unchanged.
/// This is because we don't have information about the fields/columns names otherwise.
pub fn cake_select_fields(
  value: s.Select,
  converter: c.Converter(a),
) -> s.Select {
  case converter |> c.type_def {
    c.Object(fields) -> {
      value
      |> s.selects(list.map(fields, fn(f) { s.col(f.0) }))
    }
    _ -> {
      io.println_error("Cannot select non object values")
      value
    }
  }
}

/// Decode a Dynamic value from a database row using the provided converter.
pub fn cake_decode(
  converter: c.Converter(a),
) -> fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError)) {
  fn(value) {
    value
    |> decode(c.type_def(converter))
    |> result.then(c.decode(converter))
  }
}

fn encode_insert(v: c.GlitrValue) -> i.InsertRow {
  case v {
    c.ObjectValue(fields) -> {
      i.row(list.map(fields, fn(f) { encode_insert_value(f.1) }))
    }
    _ -> i.row([])
  }
}

fn encode_insert_value(val: c.GlitrValue) -> i.InsertValue {
  case val {
    c.StringValue(v) -> i.string(v)
    c.BoolValue(v) -> i.bool(v)
    c.IntValue(v) -> i.int(v)
    c.FloatValue(v) -> i.float(v)
    c.NullValue -> i.null()
    c.OptionalValue(option.None) -> i.null()
    c.OptionalValue(option.Some(v)) -> encode_insert_value(v)
    _ -> j.encode_value(val) |> json.to_string |> i.string
  }
}

fn encode_update(val: #(String, c.GlitrValue)) -> u.UpdateSet {
  case val.1 {
    c.StringValue(v) -> u.set_string(val.0, v)
    c.BoolValue(v) -> u.set_bool(val.0, v)
    c.IntValue(v) -> u.set_int(val.0, v)
    c.FloatValue(v) -> u.set_float(val.0, v)
    c.NullValue -> u.set_null(val.0)
    c.OptionalValue(option.None) -> u.set_null(val.0)
    c.OptionalValue(option.Some(v)) -> encode_update(#(val.0, v))
    v -> u.set_string(val.0, j.encode_value(v) |> json.to_string)
  }
}

fn decode(
  of: c.GlitrType,
) -> fn(dynamic.Dynamic) -> Result(c.GlitrValue, List(dynamic.DecodeError)) {
  fn(dyn) {
    case of {
      c.Object(fields) ->
        list.fold(fields, #(0, Ok([])), fn(acc, field) {
          let fields_res = case acc.1, decode_field(dyn, field.1, acc.0) {
            Ok(res), Ok(val) -> Ok(list.append(res, [#(field.0, val)]))
            Ok(_), Error(err) | Error(err), Ok(_) -> Error(err)
            Error(errs), Error(err) -> Error(list.append(errs, err))
          }
          #(acc.0 + 1, fields_res)
        }).1
        |> result.map(c.ObjectValue)
      _ -> Error([dynamic.DecodeError("Object", type_as_str(of), [])])
    }
  }
}

fn decode_field(
  dyn: dynamic.Dynamic,
  field: c.GlitrType,
  index: Int,
) -> Result(c.GlitrValue, List(dynamic.DecodeError)) {
  dyn |> dynamic.element(index, decode_value(field))
}

fn decode_value(
  of: c.GlitrType,
) -> fn(dynamic.Dynamic) -> Result(c.GlitrValue, List(dynamic.DecodeError)) {
  case of {
    c.String -> fn(val) { val |> dynamic.string() |> result.map(c.StringValue) }
    c.Bool -> fn(val) { val |> dynamic.bool() |> result.map(c.BoolValue) }
    c.Float -> fn(val) { val |> dynamic.float() |> result.map(c.FloatValue) }
    c.Int -> fn(val) { val |> dynamic.int() |> result.map(c.IntValue) }
    c.Null -> fn(_val) { Ok(c.NullValue) }
    c.Optional(of) -> fn(val) {
      val |> dynamic.optional(decode(of)) |> result.map(c.OptionalValue)
    }
    _ -> fn(val) {
      val
      |> dynamic.string()
      |> result.then(fn(v) {
        v
        |> json.decode(j.decode_value(of))
        |> result.map_error(fn(err) {
          case err {
            json.UnexpectedFormat(errs) -> errs
            _ -> []
          }
        })
      })
    }
  }
}

fn type_as_str(of: c.GlitrType) -> String {
  case of {
    c.Bool -> "Bool"
    c.Dict(_, _) -> "Dict"
    c.Enum(_) -> "Enum"
    c.Float -> "Float"
    c.Int -> "Int"
    c.List(_) -> "List"
    c.Null -> "Null"
    c.Object(_) -> "Object"
    c.Optional(_) -> "Optional"
    c.Result(_, _) -> "Result"
    c.String -> "String"
    c.BitArray -> "BitArray"
    c.Dynamic -> "Dynamic"
  }
}
