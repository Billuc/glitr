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
