import gleam/json
import gleeunit/should
import glitr/convert as c
import glitr/convert/json as j

type TestType {
  TestType(a: String, b: Int)
}

pub fn simple_object_decode_test() {
  let test_converter =
    c.object({
      use a <- c.field("a", fn(v: TestType) { Ok(v.a) }, c.string())
      use b <- c.field("b", fn(v: TestType) { Ok(v.b) }, c.int())
      c.success(TestType(a, b))
    })

  json.decode("{\"a\": \"Age\", \"b\": 28}", j.json_decode(test_converter))
  |> should.be_ok
  |> should.equal(TestType("Age", 28))
}

pub fn simple_object_encode_test() {
  let test_converter =
    c.object({
      use a <- c.field("a", fn(v: TestType) { Ok(v.a) }, c.string())
      use b <- c.field("b", fn(v: TestType) { Ok(v.b) }, c.int())
      c.success(TestType(a, b))
    })

  TestType("Tom", 57)
  |> j.json_encode(test_converter)
  |> should.equal(
    json.object([#("a", json.string("Tom")), #("b", json.int(57))]),
  )
}

type ComplexType {
  ComplexType(first: List(String), second: TestType)
}

pub fn complex_type_decode_test() {
  let test_converter =
    c.object({
      use first <- c.field(
        "first",
        fn(v: ComplexType) { Ok(v.first) },
        c.list(c.string()),
      )
      use second <- c.field(
        "second",
        fn(v: ComplexType) { Ok(v.second) },
        c.object({
          use a <- c.field("a", fn(v: TestType) { Ok(v.a) }, c.string())
          use b <- c.field("b", fn(v: TestType) { Ok(v.b) }, c.int())
          c.success(TestType(a, b))
        }),
      )
      c.success(ComplexType(first:, second:))
    })

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

pub fn complex_type_encode_test() {
  let test_converter =
    c.object({
      use first <- c.field(
        "first",
        fn(v: ComplexType) { Ok(v.first) },
        c.list(c.string()),
      )
      use second <- c.field(
        "second",
        fn(v: ComplexType) { Ok(v.second) },
        c.object({
          use a <- c.field("a", fn(v: TestType) { Ok(v.a) }, c.string())
          use b <- c.field("b", fn(v: TestType) { Ok(v.b) }, c.int())
          c.success(TestType(a, b))
        }),
      )
      c.success(ComplexType(first:, second:))
    })

  ComplexType(["hello, world", "foo"], TestType("bar", 0))
  |> j.json_encode(test_converter)
  |> should.equal(
    json.object([
      #(
        "first",
        json.preprocessed_array([
          json.string("hello, world"),
          json.string("foo"),
        ]),
      ),
      #(
        "second",
        json.object([#("a", json.string("bar")), #("b", json.int(0))]),
      ),
    ]),
  )
}

pub type TestEnum {
  VariantA(msg: String)
  VariantB(msg: String)
  VariantC(age: Int)
}

pub fn enum_decode_test() {
  let variant_a_converter =
    c.object({
      use msg <- c.field(
        "msg",
        fn(v) {
          case v {
            VariantA(msg) -> Ok(msg)
            _ -> Error(Nil)
          }
        },
        c.string(),
      )
      c.success(VariantA(msg:))
    })
  let variant_b_converter =
    c.object({
      use msg <- c.field(
        "msg",
        fn(v) {
          case v {
            VariantB(msg) -> Ok(msg)
            _ -> Error(Nil)
          }
        },
        c.string(),
      )
      c.success(VariantB(msg:))
    })
  let variant_c_converter =
    c.object({
      use age <- c.field(
        "age",
        fn(v) {
          case v {
            VariantC(age) -> Ok(age)
            _ -> Error(Nil)
          }
        },
        c.int(),
      )
      c.success(VariantC(age:))
    })

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

pub fn enum_encode_test() {
  let variant_a_converter =
    c.object({
      use msg <- c.field(
        "msg",
        fn(v) {
          case v {
            VariantA(msg) -> Ok(msg)
            _ -> Error(Nil)
          }
        },
        c.string(),
      )
      c.success(VariantA(msg:))
    })
  let variant_b_converter =
    c.object({
      use msg <- c.field(
        "msg",
        fn(v) {
          case v {
            VariantB(msg) -> Ok(msg)
            _ -> Error(Nil)
          }
        },
        c.string(),
      )
      c.success(VariantB(msg:))
    })
  let variant_c_converter =
    c.object({
      use age <- c.field(
        "age",
        fn(v) {
          case v {
            VariantC(age) -> Ok(age)
            _ -> Error(Nil)
          }
        },
        c.int(),
      )
      c.success(VariantC(age:))
    })

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

  VariantA("i am variant a")
  |> j.json_encode(test_converter)
  |> should.equal(
    json.object([
      #("variant", json.string("VariantA")),
      #("value", json.object([#("msg", json.string("i am variant a"))])),
    ]),
  )

  VariantB("i am variant b")
  |> j.json_encode(test_converter)
  |> should.equal(
    json.object([
      #("variant", json.string("VariantB")),
      #("value", json.object([#("msg", json.string("i am variant b"))])),
    ]),
  )

  VariantC(2)
  |> j.json_encode(test_converter)
  |> should.equal(
    json.object([
      #("variant", json.string("VariantC")),
      #("value", json.object([#("age", json.int(2))])),
    ]),
  )
}
