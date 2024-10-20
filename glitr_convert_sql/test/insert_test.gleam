import gleeunit/should
import glitr/convert
import glitr/convert/sql

pub type User {
  User(name: String, age: Int)
}

pub fn insert_test() {
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

  let my_user = User("Georges", 1)

  sql.insert("users", user_converter, [my_user])
  |> should.equal("INSERT INTO users (name, age) VALUES ('Georges', 1);")
}

pub fn insert_multiple_test() {
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

  let georges = User("Georges", 1)
  let nemo = User("Nemo", 23)

  sql.insert("users", user_converter, [georges, nemo])
  |> should.equal(
    "INSERT INTO users (name, age) VALUES ('Georges', 1), ('Nemo', 23);",
  )
}
