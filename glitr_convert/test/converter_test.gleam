import gleam/json
import gleeunit/should
import glitr_convert
import glitr_convert/converter

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_encode_test() {
  let test_converter =
    converter.object({
      use a <- converter.parameter
      use b <- converter.parameter

      TestType(a, b)
    })
    |> converter.field("a", converter.string())
    |> converter.field("b", converter.int())

  test_converter
  |> converter.encode(TestType("hello", 78))
  |> should.be_ok
  |> should.equal(
    glitr_convert.ObjectValue([
      #("a", glitr_convert.StringValue("hello")),
      #("b", glitr_convert.IntValue(78)),
    ]),
  )
}

pub fn simple_object_decode_test() {
  let test_converter =
    converter.object({
      use a <- converter.parameter
      use b <- converter.parameter

      TestType(a, b)
    })
    |> converter.field("a", converter.string())
    |> converter.field("b", converter.int())

  json.decode("{\"a\": \"Age\", \"b\": 28}", converter.json_decode(
    test_converter,
    _,
  ))
  |> should.be_ok
  |> should.equal(TestType("Age", 28))
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_encode_test() {
  let test_converter =
    converter.object({
      use first <- converter.parameter
      use second <- converter.parameter

      ComplexType(first:, second:)
    })
    |> converter.field("first", converter.list(converter.string()))
    |> converter.field(
      "second",
      converter.object({
        use a <- converter.parameter
        use b <- converter.parameter

        TestType(a, b)
      })
        |> converter.field("a", converter.string())
        |> converter.field("b", converter.int()),
    )

  test_converter
  |> converter.encode(ComplexType(
    ["Adam", "Bob", "Carmen", "Dorothy"],
    TestType("Grade", 15),
  ))
  |> should.be_ok
  |> should.equal(
    glitr_convert.ObjectValue([
      #(
        "first",
        glitr_convert.ListValue([
          glitr_convert.StringValue("Adam"),
          glitr_convert.StringValue("Bob"),
          glitr_convert.StringValue("Carmen"),
          glitr_convert.StringValue("Dorothy"),
        ]),
      ),
      #(
        "second",
        glitr_convert.ObjectValue([
          #("a", glitr_convert.StringValue("Grade")),
          #("b", glitr_convert.IntValue(15)),
        ]),
      ),
    ]),
  )
}

pub fn complex_type_decode_test() {
  let test_converter =
    converter.object({
      use first <- converter.parameter
      use second <- converter.parameter

      ComplexType(first:, second:)
    })
    |> converter.field("first", converter.list(converter.string()))
    |> converter.field(
      "second",
      converter.object({
        use a <- converter.parameter
        use b <- converter.parameter

        TestType(a, b)
      })
        |> converter.field("a", converter.string())
        |> converter.field("b", converter.int()),
    )

  json.decode(
    "{
    \"first\": [\"hello\", \"World\"],
    \"second\": {
        \"a\": \"foo\",
        \"b\": 55
      }  
    }",
    converter.json_decode(test_converter, _),
  )
  |> should.be_ok
  |> should.equal(ComplexType(["hello", "World"], TestType("foo", 55)))
}
