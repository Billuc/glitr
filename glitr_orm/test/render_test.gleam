import gleeunit/should
import glitr/orm/render
import glitr/orm/schema

pub fn render_simple_table_test() {
  let table =
    schema.define_table("users", [
      schema.integer("id") |> schema.primary_key(True),
      schema.varchar("name", 255) |> schema.not_null(),
    ])

  render.render_table_file(table)
  |> should.equal(
    "import glitr/convert
import glitr/orm
import glitr/orm/convert as orm_convert

pub type UsersDTO {
  UsersDTO(id: Int, name: String)
}

pub opaque type UsersFields {
  UsersFields(id: orm.Field(Int), name: orm.Field(String))
}

pub const table = \"users\"

pub fn fields() -> UsersFields {
  UsersFields(
    id: orm.Field(table <> \".id\", convert.int()),
    name: orm.Field(table <> \".name\", convert.string()),
  )
}

pub fn field_list() -> List(String) {
  [table <> \".id\", table <> \".name\"]
}

pub fn converter() -> convert.Converter(UsersDTO) {
  convert.object({
      use id <- convert.field(
        table <> \".id\",
        fn(v: UsersDTO) { Ok(v.id) },
        convert.int(),
      )
      use name <- convert.field(
        table <> \".name\",
        fn(v: UsersDTO) { Ok(v.name) },
        convert.string(),
      )
      convert.success(UsersDTO(id, name))
    })
}
",
  )
}
