import gleam/io
import gleeunit
import gleeunit/should
import glitr/migrate/files

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn get_migrations_test() {
  let migrations = files.get_migrations()
  io.debug(migrations)
  Ok(Nil)
}
