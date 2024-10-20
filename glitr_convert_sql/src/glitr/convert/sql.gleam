import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import glitr/convert as c
import glitr/convert/json as j

pub fn insert(
  table: String,
  converter: c.Converter(a),
  values: List(a),
) -> String {
  case converter |> c.type_def {
    c.Object(fields) -> {
      let field_names = list.map(fields, fn(f) { f.0 })

      "INSERT INTO "
      <> table
      <> " ("
      <> field_names |> string.join(", ")
      <> ") VALUES "
      <> list.map(values, fn(v) {
        v |> c.encode(converter) |> to_insert_values(field_names)
      })
      |> string.join(", ")
      <> ";"
    }
    _ -> {
      io.println_error("Cannot insert non object values")
      ""
    }
  }
}

pub fn update(
  table: String,
  converter: c.Converter(a),
  value: a,
  selector_col: String,
) -> String {
  case converter |> c.type_def {
    c.Object(_fields) -> {
      let glitr_value = value |> c.encode(converter)

      "UPDATE "
      <> table
      <> " SET "
      <> glitr_value |> to_update_values(selector_col)
      <> " WHERE "
      <> to_condition(glitr_value, selector_col)
      <> ";"
    }
    _ -> {
      io.println_error("Cannot update non object values")
      ""
    }
  }
}

pub fn select(table: String, converter: c.Converter(a)) -> String {
  case converter |> c.type_def {
    c.Object(fields) -> {
      let field_names = list.map(fields, fn(f) { f.0 })

      "SELECT " <> field_names |> string.join(", ") <> " FROM " <> table <> ";"
    }
    _ -> {
      io.println_error("Cannot select non object values")
      ""
    }
  }
}

fn to_insert_values(value: c.GlitrValue, field_names: List(String)) -> String {
  case value {
    c.ObjectValue(fields) -> {
      field_names
      |> list.map(fn(f) { list.key_find(fields, f) |> result.map(to_sql_value) })
      |> result.all
      |> result.map(fn(values) { "(" <> values |> string.join(", ") <> ")" })
      |> result.lazy_unwrap(fn() {
        io.println_error("There was an error getting some values")
        ""
      })
    }
    _ -> {
      io.println_error("Cannot insert non object values")
      ""
    }
  }
}

fn to_update_values(value: c.GlitrValue, col_to_ignore: String) -> String {
  case value {
    c.ObjectValue(fields) -> {
      fields
      |> list.filter_map(fn(v) {
        use <- bool.guard(v.0 == col_to_ignore, Error(Nil))
        Ok(v.0 <> "=" <> to_sql_value(v.1))
      })
      |> string.join(", ")
    }
    _ -> {
      io.println_error("Cannot update non object values")
      ""
    }
  }
}

fn to_condition(value: c.GlitrValue, selector_col: String) -> String {
  case value {
    c.ObjectValue(fields) -> {
      fields
      |> list.key_find(selector_col)
      |> result.map(fn(val) { selector_col <> "=" <> to_sql_value(val) })
      |> result.unwrap("NULL")
    }
    _ -> {
      io.println_error("Cannot update non object values")
      ""
    }
  }
}

fn to_sql_value(value: c.GlitrValue) -> String {
  case value {
    c.BoolValue(True) -> "1"
    c.BoolValue(False) -> "0"
    c.FloatValue(v) -> float.to_string(v)
    c.IntValue(v) -> int.to_string(v)
    c.NullValue -> "NULL"
    c.StringValue(v) -> "'" <> v <> "'"
    _ -> j.encode_value(value) |> json.to_string
  }
}
