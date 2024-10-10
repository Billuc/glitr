import gleeunit/should
import glitr/convert

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_encode_test() {
  let test_converter =
    convert.object({
      use a <- convert.parameter
      use b <- convert.parameter
      use <- convert.constructor

      TestType(a, b)
    })
    |> convert.field("a", fn(v) { Ok(v.a) }, convert.string())
    |> convert.field("b", fn(v) { Ok(v.b) }, convert.int())
    |> convert.to_converter

  TestType("hello", 78)
  |> convert.encode(test_converter)
  |> should.equal(
    convert.ObjectValue([
      #("a", convert.StringValue("hello")),
      #("b", convert.IntValue(78)),
    ]),
  )
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_encode_test() {
  let test_converter =
    convert.object({
      use first <- convert.parameter
      use second <- convert.parameter
      use <- convert.constructor

      ComplexType(first:, second:)
    })
    |> convert.field(
      "first",
      fn(v) { Ok(v.first) },
      convert.list(convert.string()),
    )
    |> convert.field(
      "second",
      fn(v) { Ok(v.second) },
      convert.object({
        use a <- convert.parameter
        use b <- convert.parameter
        use <- convert.constructor

        TestType(a, b)
      })
        |> convert.field("a", fn(v) { Ok(v.a) }, convert.string())
        |> convert.field("b", fn(v) { Ok(v.b) }, convert.int())
        |> convert.to_converter,
    )
    |> convert.to_converter

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
