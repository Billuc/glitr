import glitr/orm/compare
import glitr/orm/render
import orm/gen/schema_prev
import glitr/orm/schema

pub fn users_table() {
  schema.define_table(
    "users",
    [
      schema.varchar("id", 255) |> schema.primary_key(False),
      schema.varchar("name", 255) |> schema.not_null()
    ],
  )
}

pub fn test_table() {
  schema.define_table(
    "tests",
    [
      schema.varchar("id", 255) |> schema.primary_key(False),
      schema.varchar("name", 255) |> schema.not_null()
    ],
  )
}

pub fn tables() {
  [users_table(), test_table()]
}

pub fn main() {
  let changes = compare.compare(tables(), schema_prev.tables())
  render.render_migration_file(changes)
  render.render_table_files(tables())
}
