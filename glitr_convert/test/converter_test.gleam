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
      use <- converter.constructor

      TestType(a, b)
    })
    |> converter.field("a", fn(v) { Ok(v.a) }, converter.string())
    |> converter.field("b", fn(v) { Ok(v.b) }, converter.int())
    |> converter.to_converter

  test_converter
  |> converter.encode(TestType("hello", 78))
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
      use <- converter.constructor

      TestType(a, b)
    })
    |> converter.field("a", fn(v) { Ok(v.a) }, converter.string())
    |> converter.field("b", fn(v) { Ok(v.b) }, converter.int())
    |> converter.to_converter

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
      use <- converter.constructor

      ComplexType(first:, second:)
    })
    |> converter.field(
      "first",
      fn(v) { Ok(v.first) },
      converter.list(converter.string()),
    )
    |> converter.field(
      "second",
      fn(v) { Ok(v.second) },
      converter.object({
        use a <- converter.parameter
        use b <- converter.parameter
        use <- converter.constructor

        TestType(a, b)
      })
        |> converter.field("a", fn(v) { Ok(v.a) }, converter.string())
        |> converter.field("b", fn(v) { Ok(v.b) }, converter.int())
        |> converter.to_converter,
    )
    |> converter.to_converter

  test_converter
  |> converter.encode(ComplexType(
    ["Adam", "Bob", "Carmen", "Dorothy"],
    TestType("Grade", 15),
  ))
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
      use <- converter.constructor

      ComplexType(first:, second:)
    })
    |> converter.field(
      "first",
      fn(v) { Ok(v.first) },
      converter.list(converter.string()),
    )
    |> converter.field(
      "second",
      fn(v) { Ok(v.second) },
      converter.object({
        use a <- converter.parameter
        use b <- converter.parameter
        use <- converter.constructor

        TestType(a, b)
      })
        |> converter.field("a", fn(v) { Ok(v.a) }, converter.string())
        |> converter.field("b", fn(v) { Ok(v.b) }, converter.int())
        |> converter.to_converter,
    )
    |> converter.to_converter

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

pub type TestEnum {
  VariantA(msg: String)
  VariantB(msg: String)
  VariantC(age: Int)
}

pub fn enum_encode_test() {
  let variant_a_converter =
    converter.object({
      use msg <- converter.parameter
      use <- converter.constructor

      VariantA(msg:)
    })
    |> converter.field(
      "msg",
      fn(v) {
        case v {
          VariantA(msg) -> Ok(msg)
          _ -> Error(Nil)
        }
      },
      converter.string(),
    )
    |> converter.to_converter
  let variant_b_converter =
    converter.object({
      use msg <- converter.parameter
      use <- converter.constructor

      VariantB(msg:)
    })
    |> converter.field(
      "msg",
      fn(v) {
        case v {
          VariantB(msg) -> Ok(msg)
          _ -> Error(Nil)
        }
      },
      converter.string(),
    )
    |> converter.to_converter
  let variant_c_converter =
    converter.object({
      use age <- converter.parameter
      use <- converter.constructor

      VariantC(age:)
    })
    |> converter.field(
      "age",
      fn(v) {
        case v {
          VariantC(age) -> Ok(age)
          _ -> Error(Nil)
        }
      },
      converter.int(),
    )
    |> converter.to_converter

  let test_converter =
    converter.enum(
      fn(v: TestEnum) {
        case v {
          VariantA(_) -> "VariantA"
          VariantB(_) -> "VariantB"
          VariantC(_) -> "VariantC"
        }
      },
      [
        #("VariantA", variant_a_converter),
        #("VariantB", variant_b_converter),
        #("VariantC", variant_c_converter),
      ],
    )

  json.decode(
    "{
      \"variant\": \"VariantA\",
      \"value\": {\"msg\": \"foo\"}
    }",
    converter.json_decode(test_converter, _),
  )
  |> should.be_ok
  |> should.equal(VariantA("foo"))

  json.decode(
    "{
      \"variant\": \"VariantB\",
      \"value\": {\"msg\": \"bar\"}
    }",
    converter.json_decode(test_converter, _),
  )
  |> should.be_ok
  |> should.equal(VariantB("bar"))

  json.decode(
    "{
      \"variant\": \"VariantC\",
      \"value\": {\"age\": 21}
    }",
    converter.json_decode(test_converter, _),
  )
  |> should.be_ok
  |> should.equal(VariantC(21))
}
