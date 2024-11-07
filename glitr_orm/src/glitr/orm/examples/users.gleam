import glitr/convert
import glitr/orm
import glitr/orm/convert as orm_convert

pub type UsersDTO {
  UsersDTO(id: String, name: String)
}

pub opaque type UsersFields {
  UsersFields(id: orm.Field(String), name: orm.Field(String))
}

pub const table = "users"

pub fn fields() -> UsersFields {
  UsersFields(
    id: orm.Field(table <> ".id", convert.string()),
    name: orm.Field(table <> ".name", convert.string()),
  )
}

pub fn field_list() -> List(String) {
  [table <> ".id", table <> ".name"]
}

pub fn converter() -> convert.Converter(UsersDTO) {
  convert.object({
    use id <- convert.field(
      table <> ".id",
      fn(v: UsersDTO) { Ok(v.id) },
      convert.string(),
    )
    use name <- convert.field(
      table <> ".name",
      fn(v: UsersDTO) { Ok(v.name) },
      convert.string(),
    )
    convert.success(UsersDTO(id, name))
  })
}
