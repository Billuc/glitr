import gleam/json
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn json_test() {
  ""
  |> json.decode(fn(_) { Ok(Nil) })
  |> should.equal(Ok(Nil))
}
