import gleam/dict
import gleam/json
import gleam/option
import gleeunit/should
import glitr_convert as types

// gleeunit test functions end in `_test`
pub fn string_encoder_test() {
  let val = "my test value"
  let encode = types.json_encode(types.String)

  val
  |> encode
  |> should.be_ok
  |> should.equal(json.string("my test value"))
}

pub fn string_encode_decode_should_be_ok_test() {
  let val = "my test value"
  let encode = types.json_encode(types.String)
  let decode = types.json_decode(types.String)

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn bool_encoder_test() {
  let val = True
  let encode = types.json_encode(types.Bool)

  val
  |> encode
  |> should.be_ok
  |> should.equal(json.bool(True))
}

pub fn bool_encode_decode_should_be_ok_test() {
  let val = True
  let encode = types.json_encode(types.Bool)
  let decode = types.json_decode(types.Bool)

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn float_encoder_test() {
  let val = 1.25
  let encode = types.json_encode(types.Float)

  val
  |> encode
  |> should.be_ok
  |> should.equal(json.float(1.25))
}

pub fn float_encode_decode_should_be_ok_test() {
  let val = 27.5
  let encode = types.json_encode(types.Float)
  let decode = types.json_decode(types.Float)

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn int_encoder_test() {
  let val = 4
  let encode = types.json_encode(types.Int)

  val
  |> encode
  |> should.be_ok
  |> should.equal(json.int(4))
}

pub fn int_encode_decode_should_be_ok_test() {
  let val = 67_889
  let encode = types.json_encode(types.Int)
  let decode = types.json_decode(types.Int)

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn null_encoder_test() {
  let val = "my test value"
  let encode = types.json_encode(types.Null)

  val
  |> encode
  |> should.be_ok
  |> should.equal(json.null())
}

pub fn null_encode_decode_should_be_ok_test() {
  let val = "my test value"
  let encode = types.json_encode(types.Null)
  let decode = types.json_decode(types.Null)

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn simple_list_encoder_test() {
  let val = [1, 2, 3]
  let encode = types.json_encode(types.List(types.Int))

  val
  |> encode
  |> should.be_ok
  |> should.equal(
    json.preprocessed_array([json.int(1), json.int(2), json.int(3)]),
  )
}

pub fn list_encode_decode_should_be_ok_test() {
  let val = [1, 2, 3]
  let encode = types.json_encode(types.List(types.Int))
  let decode = types.json_decode(types.List(types.Int))

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

type TestType {
  TestType(a: String, b: Float)
}

pub fn simple_object_encoder_test() {
  let val = TestType("may value", 67.32)
  let encode =
    types.json_encode(types.Object([#("a", types.String), #("b", types.Float)]))

  val
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([#("a", json.string("may value")), #("b", json.float(67.32))]),
  )
}

pub fn object_encode_decode_should_be_ok_test() {
  let val = TestType("hello world", 42.0)
  let encode =
    types.json_encode(types.Object([#("a", types.String), #("b", types.Float)]))
  let decode =
    types.json_decode(types.Object([#("a", types.String), #("b", types.Float)]))

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn object_list_encoder_test() {
  let val = [TestType("1", 1.0), TestType("2", 2.0)]
  let encode =
    types.json_encode(
      types.List(types.Object([#("a", types.String), #("b", types.Float)])),
    )

  val
  |> encode
  |> should.be_ok
  |> should.equal(
    json.preprocessed_array([
      json.object([#("a", json.string("1")), #("b", json.float(1.0))]),
      json.object([#("a", json.string("2")), #("b", json.float(2.0))]),
    ]),
  )
}

type ComplexTestType {
  ComplexTestType(first: List(String), second: TestType)
}

pub fn complex_object_encoder_test() {
  let val =
    ComplexTestType(
      first: ["list", "of", "strings"],
      second: TestType("may value", 67.32),
    )
  let encode =
    types.json_encode(
      types.Object([
        #("first", types.List(types.String)),
        #("second", types.Object([#("a", types.String), #("b", types.Float)])),
      ]),
    )

  val
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([
      #(
        "first",
        json.preprocessed_array([
          json.string("list"),
          json.string("of"),
          json.string("strings"),
        ]),
      ),
      #(
        "second",
        json.object([
          #("a", json.string("may value")),
          #("b", json.float(67.32)),
        ]),
      ),
    ]),
  )
}

pub fn simple_dict_encoder_test() {
  let val = dict.from_list([#("a", 1), #("b", 2)])
  let encode = types.json_encode(types.Dict(types.String, types.Int))

  val
  |> encode
  |> should.be_ok
  |> should.equal(
    json.preprocessed_array([
      json.preprocessed_array([json.string("a"), json.int(1)]),
      json.preprocessed_array([json.string("b"), json.int(2)]),
    ]),
  )
}

pub fn dict_encode_decode_should_be_ok_test() {
  let val = dict.from_list([#("a", 1), #("b", 2)])
  let encode = types.json_encode(types.Dict(types.String, types.Int))
  let decode = types.json_decode(types.Dict(types.String, types.Int))

  val
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
  |> should.equal(
    types.DictValue(
      dict.from_list([
        #(types.StringValue("a"), types.IntValue(1)),
        #(types.StringValue("b"), types.IntValue(2)),
      ]),
    ),
  )
}

pub fn optional_encoder_test() {
  let val_none = option.None
  let val_some = option.Some("foo")
  let encode = types.json_encode(types.Optional(types.String))

  val_none
  |> encode
  |> should.be_ok
  |> should.equal(json.null())

  val_some
  |> encode
  |> should.be_ok
  |> should.equal(json.string("foo"))
}

pub fn optional_encode_decode_should_be_ok_test() {
  let val_none = option.None
  let val_some = option.Some("foo")
  let encode = types.json_encode(types.Optional(types.String))
  let decode = types.json_decode(types.Optional(types.String))

  val_none
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
  |> should.equal(types.OptionalValue(option.None))

  val_some
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
  |> should.equal(types.OptionalValue(option.Some(types.StringValue("foo"))))
}

type TestTypeWithOption {
  TestTypeWithOption(a: String, b: option.Option(Float))
}

pub fn object_with_option_encoder_test() {
  let val_none = TestTypeWithOption("may value", option.None)
  let val_some = TestTypeWithOption("may value", option.Some(67.32))
  let encode =
    types.json_encode(
      types.Object([#("a", types.String), #("b", types.Optional(types.Float))]),
    )

  val_none
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([#("a", json.string("may value")), #("b", json.null())]),
  )

  val_some
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([#("a", json.string("may value")), #("b", json.float(67.32))]),
  )
}

pub fn object_with_option_encode_decode_should_be_ok_test() {
  let val_none = TestTypeWithOption("may value", option.None)
  let val_some = TestTypeWithOption("may value", option.Some(67.32))
  let encode =
    types.json_encode(
      types.Object([#("a", types.String), #("b", types.Optional(types.Float))]),
    )
  let decode =
    types.json_decode(
      types.Object([#("a", types.String), #("b", types.Optional(types.Float))]),
    )

  val_none
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok

  val_some
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}

pub fn result_encoder_test() {
  let val_ok = Ok([1, 4, 9])
  let val_err = Error("something happened")
  let encode =
    types.json_encode(types.Result(types.List(types.Int), types.String))

  val_ok
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([
      #("type", json.string("ok")),
      #(
        "value",
        json.preprocessed_array([json.int(1), json.int(4), json.int(9)]),
      ),
    ]),
  )

  val_err
  |> encode
  |> should.be_ok
  |> should.equal(
    json.object([
      #("type", json.string("error")),
      #("value", json.string("something happened")),
    ]),
  )
}

pub fn result_encode_decode_should_be_ok_test() {
  let val_ok = Ok([2, 5, 8])
  let val_err = Error("404: Not Found")
  let encode =
    types.json_encode(types.Result(types.List(types.Int), types.String))
  let decode =
    types.json_decode(types.Result(types.List(types.Int), types.String))

  val_ok
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok

  val_err
  |> encode
  |> should.be_ok
  |> json.to_string
  |> json.decode(decode)
  |> should.be_ok
}
