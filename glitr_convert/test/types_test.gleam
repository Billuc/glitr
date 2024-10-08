import gleam/dict
import gleam/json
import gleam/option
import gleeunit/should
import glitr_convert as types

// gleeunit test functions end in `_test`
pub fn string_encoder_test() {
  let val = types.StringValue("my test value")

  val
  |> types.json_encode
  |> should.equal(json.string("my test value"))
}

pub fn string_encode_decode_should_be_ok_test() {
  let val = types.StringValue("my test value")

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.String))
  |> should.be_ok
  |> should.equal(val)
}

pub fn bool_encoder_test() {
  let val = types.BoolValue(True)

  val
  |> types.json_encode
  |> should.equal(json.bool(True))
}

pub fn bool_encode_decode_should_be_ok_test() {
  let val = types.BoolValue(True)

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Bool))
  |> should.be_ok
  |> should.equal(val)
}

pub fn float_encoder_test() {
  let val = types.FloatValue(1.25)

  val
  |> types.json_encode
  |> should.equal(json.float(1.25))
}

pub fn float_encode_decode_should_be_ok_test() {
  let val = types.FloatValue(27.5)

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Float))
  |> should.be_ok
  |> should.equal(val)
}

pub fn int_encoder_test() {
  let val = types.IntValue(4)

  val
  |> types.json_encode
  |> should.equal(json.int(4))
}

pub fn int_encode_decode_should_be_ok_test() {
  let val = types.IntValue(67_889)

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Int))
  |> should.be_ok
  |> should.equal(val)
}

pub fn null_encoder_test() {
  let val = types.NullValue

  val
  |> types.json_encode
  |> should.equal(json.null())
}

pub fn null_encode_decode_should_be_ok_test() {
  let val = types.NullValue

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Null))
  |> should.be_ok
  |> should.equal(val)
}

pub fn simple_list_encoder_test() {
  let val =
    types.ListValue([types.IntValue(1), types.IntValue(2), types.IntValue(3)])

  val
  |> types.json_encode
  |> should.equal(
    json.preprocessed_array([json.int(1), json.int(2), json.int(3)]),
  )
}

pub fn list_encode_decode_should_be_ok_test() {
  let val =
    types.ListValue([types.IntValue(1), types.IntValue(2), types.IntValue(3)])

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.List(types.Int)))
  |> should.be_ok
  |> should.equal(val)
}

pub fn simple_object_encoder_test() {
  let val =
    types.ObjectValue([
      #("a", types.StringValue("may value")),
      #("b", types.FloatValue(67.32)),
    ])

  val
  |> types.json_encode
  |> should.equal(
    json.object([#("a", json.string("may value")), #("b", json.float(67.32))]),
  )
}

pub fn object_encode_decode_should_be_ok_test() {
  let val =
    types.ObjectValue([
      #("a", types.StringValue("may value")),
      #("b", types.FloatValue(67.32)),
    ])

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(
    types.json_decode(types.Object([#("a", types.String), #("b", types.Float)])),
  )
  |> should.be_ok
  |> should.equal(val)
}

pub fn object_list_encoder_test() {
  let val =
    types.ListValue([
      types.ObjectValue([
        #("a", types.StringValue("1")),
        #("b", types.FloatValue(1.0)),
      ]),
      types.ObjectValue([
        #("a", types.StringValue("2")),
        #("b", types.FloatValue(2.0)),
      ]),
    ])

  val
  |> types.json_encode
  |> should.equal(
    json.preprocessed_array([
      json.object([#("a", json.string("1")), #("b", json.float(1.0))]),
      json.object([#("a", json.string("2")), #("b", json.float(2.0))]),
    ]),
  )
}

pub fn complex_object_encoder_test() {
  let val =
    types.ObjectValue([
      #(
        "first",
        types.ListValue([
          types.StringValue("list"),
          types.StringValue("of"),
          types.StringValue("strings"),
        ]),
      ),
      #(
        "second",
        types.ObjectValue([
          #("a", types.StringValue("my value")),
          #("b", types.FloatValue(67.32)),
        ]),
      ),
    ])

  val
  |> types.json_encode
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
        json.object([#("a", json.string("my value")), #("b", json.float(67.32))]),
      ),
    ]),
  )
}

@target(erlang)
pub fn simple_dict_encoder_test() {
  let val =
    types.DictValue(
      dict.from_list([
        #(types.StringValue("a"), types.IntValue(1)),
        #(types.StringValue("b"), types.IntValue(2)),
      ]),
    )

  val
  |> types.json_encode
  |> should.equal(
    json.preprocessed_array([
      json.preprocessed_array([json.string("a"), json.int(1)]),
      json.preprocessed_array([json.string("b"), json.int(2)]),
    ]),
  )
}

@target(javascript)
pub fn simple_dict_encoder_test() {
  let val =
    types.DictValue(
      dict.from_list([
        #(types.StringValue("a"), types.IntValue(1)),
        #(types.StringValue("b"), types.IntValue(2)),
      ]),
    )

  val
  |> types.json_encode
  |> should.equal(
    json.preprocessed_array([
      json.preprocessed_array([json.string("b"), json.int(2)]),
      json.preprocessed_array([json.string("a"), json.int(1)]),
    ]),
  )
}

pub fn dict_encode_decode_should_be_ok_test() {
  let val =
    types.DictValue(
      dict.from_list([
        #(types.StringValue("a"), types.IntValue(1)),
        #(types.StringValue("b"), types.IntValue(2)),
      ]),
    )

  val
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Dict(types.String, types.Int)))
  |> should.be_ok
  |> should.equal(val)
}

pub fn optional_encoder_test() {
  let val_none = types.OptionalValue(option.None)
  let val_some = types.OptionalValue(option.Some(types.StringValue("foo")))

  val_none
  |> types.json_encode
  |> should.equal(json.null())

  val_some
  |> types.json_encode
  |> should.equal(json.string("foo"))
}

pub fn optional_encode_decode_should_be_ok_test() {
  let val_none = types.OptionalValue(option.None)
  let val_some = types.OptionalValue(option.Some(types.StringValue("foo")))

  val_none
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Optional(types.String)))
  |> should.be_ok
  |> should.equal(val_none)

  val_some
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(types.Optional(types.String)))
  |> should.be_ok
  |> should.equal(val_some)
}

pub fn object_with_option_encoder_test() {
  let val_none =
    types.ObjectValue([
      #("a", types.StringValue("test")),
      #("b", types.OptionalValue(option.None)),
    ])
  let val_some =
    types.ObjectValue([
      #("a", types.StringValue("test2")),
      #("b", types.OptionalValue(option.Some(types.FloatValue(99.999)))),
    ])

  val_none
  |> types.json_encode
  |> should.equal(
    json.object([#("a", json.string("test")), #("b", json.null())]),
  )

  val_some
  |> types.json_encode
  |> should.equal(
    json.object([#("a", json.string("test2")), #("b", json.float(99.999))]),
  )
}

pub fn object_with_option_encode_decode_should_be_ok_test() {
  let val_none =
    types.ObjectValue([
      #("a", types.StringValue("test")),
      #("b", types.OptionalValue(option.None)),
    ])
  let val_some =
    types.ObjectValue([
      #("a", types.StringValue("test2")),
      #("b", types.OptionalValue(option.Some(types.FloatValue(99.999)))),
    ])

  val_none
  |> types.json_encode
  |> json.to_string
  |> json.decode(
    types.json_decode(
      types.Object([#("a", types.String), #("b", types.Optional(types.Float))]),
    ),
  )
  |> should.be_ok
  |> should.equal(val_none)

  val_some
  |> types.json_encode
  |> json.to_string
  |> json.decode(
    types.json_decode(
      types.Object([#("a", types.String), #("b", types.Optional(types.Float))]),
    ),
  )
  |> should.be_ok
  |> should.equal(val_some)
}

pub fn result_encoder_test() {
  let val_ok =
    types.ResultValue(
      Ok(
        types.ListValue([
          types.IntValue(1),
          types.IntValue(4),
          types.IntValue(9),
        ]),
      ),
    )
  let val_err =
    types.ResultValue(Error(types.StringValue("something happened")))

  val_ok
  |> types.json_encode
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
  |> types.json_encode
  |> should.equal(
    json.object([
      #("type", json.string("error")),
      #("value", json.string("something happened")),
    ]),
  )
}

pub fn result_encode_decode_should_be_ok_test() {
  let val_ok =
    types.ResultValue(
      Ok(
        types.ListValue([
          types.IntValue(2),
          types.IntValue(5),
          types.IntValue(8),
        ]),
      ),
    )
  let val_err = types.ResultValue(Error(types.StringValue("404: NotFound")))

  val_ok
  |> types.json_encode
  |> json.to_string
  |> json.decode(
    types.json_decode(types.Result(types.List(types.Int), types.String)),
  )
  |> should.be_ok
  |> should.equal(val_ok)

  val_err
  |> types.json_encode
  |> json.to_string
  |> json.decode(
    types.json_decode(types.Result(types.List(types.Int), types.String)),
  )
  |> should.be_ok
  |> should.equal(val_err)
}

pub fn enum_encoder_test() {
  let val_a =
    types.EnumValue(
      "VariantA",
      types.ObjectValue([#("a", types.StringValue("this is a test"))]),
    )
  let val_b =
    types.EnumValue("VariantB", types.ObjectValue([#("b", types.IntValue(1))]))

  val_a
  |> types.json_encode
  |> should.equal(
    json.object([
      #("variant", json.string("VariantA")),
      #("value", json.object([#("a", json.string("this is a test"))])),
    ]),
  )

  val_b
  |> types.json_encode
  |> should.equal(
    json.object([
      #("variant", json.string("VariantB")),
      #("value", json.object([#("b", json.int(1))])),
    ]),
  )
}

pub fn enum_encode_decode_should_be_ok_test() {
  let val_a =
    types.EnumValue(
      "VariantA",
      types.ObjectValue([#("a", types.StringValue("this is a test"))]),
    )
  let val_b =
    types.EnumValue("VariantB", types.ObjectValue([#("b", types.IntValue(1))]))
  let type_def =
    types.Enum([
      #("VariantA", types.Object([#("a", types.String)])),
      #("VariantB", types.Object([#("b", types.Int)])),
    ])

  val_a
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(type_def))
  |> should.be_ok
  |> should.equal(val_a)

  val_b
  |> types.json_encode
  |> json.to_string
  |> json.decode(types.json_decode(type_def))
  |> should.be_ok
  |> should.equal(val_b)
}
