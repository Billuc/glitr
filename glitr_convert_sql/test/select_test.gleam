import gleeunit/should
import glitr/convert
import glitr/convert/sql

pub type User {
  User(name: String, age: Int)
}

pub fn select_test() {
  let user_converter =
    convert.object({
      use name <- convert.field(
        "name",
        fn(u: User) { Ok(u.name) },
        convert.string(),
      )
      use age <- convert.field("age", fn(u: User) { Ok(u.age) }, convert.int())
      convert.success(User(name:, age:))
    })

  sql.select("users", user_converter)
  |> should.equal("SELECT name, age FROM users;")
}
