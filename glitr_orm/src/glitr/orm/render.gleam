import glance
import glance_printer
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import gleam/string_builder
import glitr/orm/compare
import glitr/orm/generate
import glitr/orm/types
import simplifile

fn capitalise(str: String) -> String {
  str |> string.split("_") |> list.map(string.capitalise) |> string.join("")
}

pub fn render_table_files(tables: List(types.Table)) -> Nil {
  case tables {
    [] -> Nil
    [t, ..rest] -> {
      render_table_file(t)
      render_table_files(rest)
    }
  }
}

pub fn render_table_file(table: types.Table) -> Nil {
  let path = generate.base_dir <> "/" <> table.name <> ".gleam"
  let _ = simplifile.create_file(path)
  let content = render_table(table)

  case simplifile.write(path, content) {
    Error(err) -> io.println_error(simplifile.describe_error(err))
    Ok(_) -> Nil
  }
}

pub fn render_table(table: types.Table) -> String {
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

fn render_type(table: types.Table) -> String {
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

fn render_fields(table: types.Table) -> String {
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

fn render_fields_fn(table: types.Table) -> String {
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

fn render_field_list_fn(table: types.Table) -> String {
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

fn render_converter(table: types.Table) -> String {
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

pub fn render_migration_file(changes: List(compare.SchemaChange)) -> Nil {
  let path = generate.gen_dir <> "/migration.sql"
  let _ = simplifile.create_file(path)
  let content = render_migration(changes)

  case simplifile.write(path, content) {
    Error(err) -> io.println_error(simplifile.describe_error(err))
    Ok(_) -> Nil
  }
}

fn render_migration(changes: List(compare.SchemaChange)) -> String {
  list.map(changes, fn(ch) { render_schema_change(ch) })
  |> string.join("\n")
}

fn render_schema_change(change: compare.SchemaChange) -> String {
  case change {
    compare.NewTable(t) -> render_create_table(t)
    compare.DropTable(t) -> render_drop_table(t)
    compare.TableChanges(t, ch) -> render_table_changes(t, ch)
  }
}

fn render_create_table(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("CREATE TABLE ")
  |> string_builder.append(table.name)
  |> string_builder.append("(\n\t")
  |> string_builder.append(render_sql_fields(table.name, table.columns))
  |> string_builder.append("\n);")
  |> string_builder.to_string
}

fn render_drop_table(table: types.Table) -> String {
  string_builder.new()
  |> string_builder.append("DROP TABLE ")
  |> string_builder.append(table.name)
  |> string_builder.append(";")
  |> string_builder.to_string
}

fn render_sql_fields(table_name: String, fields: List(types.Column)) -> String {
  list.map(fields, fn(f) { render_sql_field(table_name, f, True) })
  |> string.join(",\n")
}

fn append_if(
  builder: string_builder.StringBuilder,
  predicate: Bool,
  suffix: String,
) -> string_builder.StringBuilder {
  case predicate {
    False -> builder
    True -> builder |> string_builder.append(suffix)
  }
}

fn render_sql_field(
  table_name: String,
  field: types.Column,
  with_constraints: Bool,
) -> String {
  let builder =
    string_builder.new()
    |> string_builder.append(field.name)
    |> string_builder.append(" ")
    |> string_builder.append(field_type_to_db_type(field.type_))

  use <- bool.guard(!with_constraints, builder |> string_builder.to_string)

  let builder =
    builder
    |> append_if(field.primary_key, " PRIMARY KEY")
    |> append_if(
      bool.and(field.primary_key, field.auto_increment),
      " AUTO INCREMENT",
    )
    |> append_if(field.unique, " UNIQUE")
    |> append_if(!field.nullable, " NOT NULL")

  let builder = case field.default {
    option.None -> builder
    option.Some(val) -> builder |> string_builder.append(" DEFAULT " <> val)
  }

  let builder = case field.foreign_key {
    option.None -> builder
    option.Some(ref) ->
      builder |> render_foreign_key(ref, table_name, field.name)
  }

  builder |> string_builder.to_string
}

fn render_foreign_key(
  builder: string_builder.StringBuilder,
  reference: types.Reference,
  table_name: String,
  column_name: String,
) -> string_builder.StringBuilder {
  let referenced_table = case reference.table {
    types.SelfRef -> table_name
    types.TableRef(t) -> t.name
  }

  builder
  |> string_builder.append(",\nCONSTRAINT FK_")
  |> string_builder.append(referenced_table)
  |> string_builder.append("_")
  |> string_builder.append(reference.column.name)
  |> string_builder.append(" FOREIGN KEY (")
  |> string_builder.append(column_name)
  |> string_builder.append(") REFERENCES ")
  |> string_builder.append(referenced_table)
  |> string_builder.append("(" <> reference.column.name <> ")")
  |> string_builder.append(render_on_delete(reference.on_delete))
  |> string_builder.append(render_on_update(reference.on_update))
}

fn render_on_delete(on_delete: types.OnDeleteUpdateOption) -> String {
  case on_delete {
    types.Cascade -> " ON DELETE CASCADE"
    types.NoAction -> ""
    types.SetNull -> " ON DELETE SET NULL"
  }
}

fn render_on_update(on_update: types.OnDeleteUpdateOption) -> String {
  case on_update {
    types.Cascade -> " ON UPDATE CASCADE"
    types.NoAction -> ""
    types.SetNull -> " ON UPDATE SET NULL"
  }
}

fn field_type_to_db_type(t: types.ColumnType) -> String {
  case t {
    types.Varchar(k) -> "VARCHAR(" <> int.to_string(k) <> ")"
    types.Integer -> "INTEGER"
    types.Real -> "REAL"
    types.DoublePrecision -> "DOUBLE PRECISION"
    types.Boolean -> "BOOLEAN"
    types.Date -> "DATE"
    types.Time -> "TIME"
    types.Timestamp -> "TIMESTAMP"
  }
}

fn render_table_changes(
  table_name: String,
  changes: List(compare.TableChange),
) -> String {
  string_builder.new()
  |> string_builder.append("ALTER TABLE ")
  |> string_builder.append(table_name)
  |> string_builder.append("\n")
  |> string_builder.append(render_changes(table_name, changes))
  |> string_builder.to_string
}

fn render_changes(
  table_name: String,
  changes: List(compare.TableChange),
) -> String {
  list.map(changes, fn(ch) { render_change(table_name, ch) })
  |> string.join("\n")
}

fn render_change(table_name: String, change: compare.TableChange) -> String {
  case change {
    compare.ChangeType(_, _, _) -> ""
    // TODO
    compare.DropColumn(col) ->
      "DROP " <> render_sql_field(table_name, col, False)
    compare.NewColumn(col) -> "ADD " <> render_sql_field(table_name, col, True)
  }
}
