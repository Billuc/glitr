import gleam/json
import gleeunit/should
import glitr_convert/converters as c
import glitr_convert/json as j

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_decode_test() {
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

  json.decode("{\"a\": \"Age\", \"b\": 28}", j.json_decode(test_converter))
  |> should.be_ok
  |> should.equal(TestType("Age", 28))
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_decode_test() {
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

  json.decode(
    "{
    \"first\": [\"hello\", \"World\"],
    \"second\": {
        \"a\": \"foo\",
        \"b\": 55
      }  
    }",
    j.json_decode(test_converter),
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
    c.object({
      use msg <- c.parameter
      use <- c.constructor

      VariantA(msg:)
    })
    |> c.field(
      "msg",
      fn(v) {
        case v {
          VariantA(msg) -> Ok(msg)
          _ -> Error(Nil)
        }
      },
      c.string(),
    )
    |> c.to_converter
  let variant_b_converter =
    c.object({
      use msg <- c.parameter
      use <- c.constructor

      VariantB(msg:)
    })
    |> c.field(
      "msg",
      fn(v) {
        case v {
          VariantB(msg) -> Ok(msg)
          _ -> Error(Nil)
        }
      },
      c.string(),
    )
    |> c.to_converter
  let variant_c_converter =
    c.object({
      use age <- c.parameter
      use <- c.constructor

      VariantC(age:)
    })
    |> c.field(
      "age",
      fn(v) {
        case v {
          VariantC(age) -> Ok(age)
          _ -> Error(Nil)
        }
      },
      c.int(),
    )
    |> c.to_converter

  let test_converter =
    c.enum(
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
    j.json_decode(test_converter),
  )
  |> should.be_ok
  |> should.equal(VariantA("foo"))

  json.decode(
    "{
      \"variant\": \"VariantB\",
      \"value\": {\"msg\": \"bar\"}
    }",
    j.json_decode(test_converter),
  )
  |> should.be_ok
  |> should.equal(VariantB("bar"))

  json.decode(
    "{
      \"variant\": \"VariantC\",
      \"value\": {\"age\": 21}
    }",
    j.json_decode(test_converter),
  )
  |> should.be_ok
  |> should.equal(VariantC(21))
}
