import gleeunit/should
import glitr/convert
import glitr/convert/sql

pub type User {
  User(name: String, age: Int)
}

pub fn update_test() {
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

  let my_user = User("Georges", 1)

  sql.update("users", user_converter, my_user, "name")
  |> should.equal("UPDATE users SET age=1 WHERE name='Georges';")
}

pub fn update_wrong_col_test() {
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

  let georges = User("Georges", 1)

  sql.update("users", user_converter, georges, "id")
  |> should.equal("UPDATE users SET name='Georges', age=1 WHERE NULL;")
}
