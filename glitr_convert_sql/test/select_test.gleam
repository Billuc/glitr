import gleeunit/should
import glitr/convert
import glitr/convert/sql

pub type User {
  User(name: String, age: Int)
}

pub fn select_test() {
  let user_converter =
    convert.object({
      use name <- convert.parameter
      use age <- convert.parameter
      use <- convert.constructor
      User(name:, age:)
    })
    |> convert.field("name", fn(u) { Ok(u.name) }, convert.string())
    |> convert.field("age", fn(u) { Ok(u.age) }, convert.int())
    |> convert.to_converter

  sql.select("users", user_converter)
  |> should.equal("SELECT name, age FROM users;")
}
