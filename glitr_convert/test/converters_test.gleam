import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import glitr/convert

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_encode_test() {
  let test_converter =
    convert.object({
      use a <- convert.field("a", fn(v: TestType) { Ok(v.a) }, convert.string())
      use b <- convert.field("b", fn(v: TestType) { Ok(v.b) }, convert.int())
      convert.success(TestType(a, b))
    })

  TestType("hello", 78)
  |> convert.encode(test_converter)
  |> should.equal(
    convert.ObjectValue([
      #("a", convert.StringValue("hello")),
      #("b", convert.IntValue(78)),
    ]),
  )
}

pub fn simple_object_type_def_test() {
  let test_converter =
    convert.object({
      use a <- convert.field("a", fn(v: TestType) { Ok(v.a) }, convert.string())
      use b <- convert.field("b", fn(v: TestType) { Ok(v.b) }, convert.int())
      convert.success(TestType(a, b))
    })

  test_converter
  |> convert.type_def
  |> should.equal(convert.Object([#("a", convert.String), #("b", convert.Int)]))
}

pub fn simple_tuple_test() {
  let test_converter =
    convert.object({
      use a <- convert.field(
        "0",
        fn(v: #(Int, String)) { Ok(v.0) },
        convert.int(),
      )
      use b <- convert.field(
        "1",
        fn(v: #(Int, String)) { Ok(v.1) },
        convert.string(),
      )
      convert.success(#(a, b))
    })

  #(42, "lorem ipsum")
  |> convert.encode(test_converter)
  |> should.equal(
    convert.ObjectValue([
      #("0", convert.IntValue(42)),
      #("1", convert.StringValue("lorem ipsum")),
    ]),
  )
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_encode_test() {
  let test_converter =
    convert.object({
      use first <- convert.field(
        "first",
        fn(v: ComplexType) { Ok(v.first) },
        convert.list(convert.string()),
      )
      use second <- convert.field(
        "second",
        fn(v: ComplexType) { Ok(v.second) },
        convert.object({
          use a <- convert.field(
            "a",
            fn(v: TestType) { Ok(v.a) },
            convert.string(),
          )
          use b <- convert.field(
            "b",
            fn(v: TestType) { Ok(v.b) },
            convert.int(),
          )
          convert.success(TestType(a, b))
        }),
      )
      convert.success(ComplexType(first:, second:))
    })

  ComplexType(["Adam", "Bob", "Carmen", "Dorothy"], TestType("Grade", 15))
  |> convert.encode(test_converter)
  |> should.equal(
    convert.ObjectValue([
      #(
        "first",
        convert.ListValue([
          convert.StringValue("Adam"),
          convert.StringValue("Bob"),
          convert.StringValue("Carmen"),
          convert.StringValue("Dorothy"),
        ]),
      ),
      #(
        "second",
        convert.ObjectValue([
          #("a", convert.StringValue("Grade")),
          #("b", convert.IntValue(15)),
        ]),
      ),
    ]),
  )
}

pub type Date {
  Date(year: Int, month: Int, day: Int)
}

pub fn converter_map_test() {
  // We are storing the date as a string for optimized memory storage
  let date_converter = {
    convert.string()
    |> convert.map(
      fn(v: Date) {
        [v.year, v.month, v.day] |> list.map(int.to_string) |> string.join("/")
      },
      fn(v: String) {
        let elems =
          string.split(v, "/")
          |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
        case elems {
          [y, m, d, ..] -> Date(y, m, d)
          [y, m] -> Date(y, m, -1)
          [y] -> Date(y, -1, -1)
          [] -> Date(-1, -1, -1)
        }
      },
    )
  }

  Date(2024, 10, 30)
  |> convert.encode(date_converter)
  |> should.equal(convert.StringValue("2024/10/30"))

  convert.StringValue("2013/10/29")
  |> convert.decode(date_converter)
  |> should.be_ok
  |> should.equal(Date(2013, 10, 29))
}
