import glance
import glance_printer
import gleam/int
import gleam/list
import gleam/string
import gleam/string_builder
import glitr/orm/types

fn capitalise(str: String) -> String {
  str |> string.split("_") |> list.map(string.capitalise) |> string.join("")
}

pub fn render_table_file(table: types.Table) {
  let content =
    string_builder.new()
    |> string_builder.append("import glitr/convert\n")
    |> string_builder.append("import glitr/orm\n")
    |> string_builder.append("import glitr/orm/convert as orm_convert\n\n")
    |> string_builder.append(render_type(table))
    |> string_builder.append("\n\n")
    |> string_builder.append(render_fields(table))
    |> string_builder.append("\n\n")
    |> string_builder.append("pub const table = \"" <> table.name <> "\"\n\n")
    |> string_builder.append(render_fields_fn(table))
    |> string_builder.append("\n\n")
    |> string_builder.append(render_field_list_fn(table))
    |> string_builder.append("\n\n")
    |> string_builder.append(render_converter(table))
    |> string_builder.to_string

  let module = glance.module(content)

  case module {
    Error(err) -> {
      case err {
        glance.UnexpectedEndOfInput -> "Unexpected end of input"
        glance.UnexpectedToken(_token, pos) ->
          "Unexpected token at position " <> int.to_string(pos.byte_offset)
      }
    }
    Ok(m) -> glance_printer.print(m)
  }
}

pub fn render_type(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("pub type ")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("DTO {\n\t")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("DTO(")
  |> string_builder.append(render_type_fields(table.columns))
  |> string_builder.append(")\n}")
  |> string_builder.to_string
}

fn render_type_fields(fields: List(types.Column)) -> String {
  list.map(fields, fn(f) { f.name <> ": " <> field_to_gleam_type(f) })
  |> string.join(", ")
}

fn field_to_gleam_type(field: types.Column) -> String {
  case field.type_ {
    types.Varchar(_) -> "String"
    types.Integer -> "Int"
    types.Real | types.DoublePrecision -> "Float"
    types.Boolean -> "Bool"
    types.Date -> "orm.Date"
    types.Time -> "orm.Time"
    types.Timestamp -> "orm.Timestamp"
  }
}

pub fn render_fields(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("pub opaque type ")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("Fields {\n\t")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("Fields(")
  |> string_builder.append(render_fields_fields(table.columns))
  |> string_builder.append(")\n}")
  |> string_builder.to_string
}

fn render_fields_fields(fields: List(types.Column)) -> String {
  list.map(fields, fn(f) {
    f.name <> ": orm.Field(" <> field_to_gleam_type(f) <> ")"
  })
  |> string.join(", ")
}

pub fn render_fields_fn(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("pub fn fields() -> ")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("Fields {\n\t")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("Fields(")
  |> string_builder.append(render_fields_fn_fields(table.columns))
  |> string_builder.append(")\n}")
  |> string_builder.to_string
}

fn render_fields_fn_fields(fields: List(types.Column)) -> String {
  list.map(fields, fn(f) {
    f.name
    <> ": orm.Field(table <> \"."
    <> f.name
    <> "\", "
    <> field_to_converter(f)
    <> ")"
  })
  |> string.join(", ")
}

pub fn render_field_list_fn(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("pub fn field_list() -> List(String) {\n\t[")
  |> string_builder.append(
    list.map(table.columns, fn(f) { "table <> \"." <> f.name <> "\"" })
    |> string.join(", "),
  )
  |> string_builder.append("]\n}")
  |> string_builder.to_string
}

fn field_to_converter(field: types.Column) -> String {
  case field.type_ {
    types.Varchar(_) -> "convert.string()"
    types.Integer -> "convert.int()"
    types.Real | types.DoublePrecision -> "convert.float()"
    types.Boolean -> "convert.bool()"
    types.Date -> "orm_convert.date()"
    types.Time -> "orm_convert.time()"
    types.Timestamp -> "orm_convert.timestamp()"
  }
}

pub fn render_converter(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("pub fn converter() -> convert.Converter(")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("DTO) {\n\t")
  |> string_builder.append("convert.object({\n")
  |> string_builder.append(render_convert_fields(table))
  |> string_builder.append("\n\t\tconvert.success(")
  |> string_builder.append(capitalise(table.name))
  |> string_builder.append("DTO(")
  |> string_builder.append(
    list.map(table.columns, fn(f) { f.name }) |> string.join(", "),
  )
  |> string_builder.append("))\n\t})\n}")
  |> string_builder.to_string
}

fn render_convert_fields(table: types.Table) -> String {
  list.map(table.columns, fn(f) {
    string_builder.new()
    |> string_builder.append("\t\tuse ")
    |> string_builder.append(f.name)
    |> string_builder.append(" <- convert.field(table <> \".")
    |> string_builder.append(f.name)
    |> string_builder.append("\", fn(v: ")
    |> string_builder.append(capitalise(table.name))
    |> string_builder.append("DTO) { Ok(v.")
    |> string_builder.append(f.name)
    |> string_builder.append(") }, ")
    |> string_builder.append(field_to_converter(f))
    |> string_builder.append(")")
    |> string_builder.to_string
  })
  |> string.join("\n")
}
