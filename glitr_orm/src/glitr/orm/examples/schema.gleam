import glitr/orm/schema

pub fn users_table() {
  schema.define_table("users", [
    schema.varchar("id", 255) |> schema.primary_key(False),
    schema.varchar("name", 255) |> schema.not_null(),
  ])
}
