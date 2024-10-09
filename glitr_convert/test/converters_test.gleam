import gleeunit/should
import glitr_convert
import glitr_convert/converters as c

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_encode_test() {
  let test_converter =
    c.object({
      use a <- c.parameter
      use b <- c.parameter
      use <- c.constructor

      TestType(a, b)
    })
    |> c.field("a", fn(v) { Ok(v.a) }, c.string())
    |> c.field("b", fn(v) { Ok(v.b) }, c.int())
    |> c.to_converter

  TestType("hello", 78)
  |> c.encode(test_converter)
  |> should.equal(
    glitr_convert.ObjectValue([
      #("a", glitr_convert.StringValue("hello")),
      #("b", glitr_convert.IntValue(78)),
    ]),
  )
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_encode_test() {
  let test_converter =
    c.object({
      use first <- c.parameter
      use second <- c.parameter
      use <- c.constructor

      ComplexType(first:, second:)
    })
    |> c.field("first", fn(v) { Ok(v.first) }, c.list(c.string()))
    |> c.field(
      "second",
      fn(v) { Ok(v.second) },
      c.object({
        use a <- c.parameter
        use b <- c.parameter
        use <- c.constructor

        TestType(a, b)
      })
        |> c.field("a", fn(v) { Ok(v.a) }, c.string())
        |> c.field("b", fn(v) { Ok(v.b) }, c.int())
        |> c.to_converter,
    )
    |> c.to_converter

  ComplexType(["Adam", "Bob", "Carmen", "Dorothy"], TestType("Grade", 15))
  |> c.encode(test_converter)
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
