import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import gleam/string

/// This type is used to define the shape of the data.  
/// It isn't meant to be used directly !  
/// It is better to use converters that use GlitrTypes internally to decode data.
pub type GlitrType {
  String
  Bool
  Float
  Int
  Dynamic
  BitArray
  Null
  List(of: GlitrType)
  Dict(key: GlitrType, value: GlitrType)
  Object(fields: List(#(String, GlitrType)))
  Optional(of: GlitrType)
  Result(result: GlitrType, error: GlitrType)
  Enum(variants: List(#(String, GlitrType)))
}

/// This type is used to represent data values.  
/// It is an intermediate type between encoded data and Gleam types.
/// It isn't meant to be used directly !  
pub type GlitrValue {
  StringValue(value: String)
  BoolValue(value: Bool)
  FloatValue(value: Float)
  IntValue(value: Int)
  DynamicValue(value: dynamic.Dynamic)
  BitArrayValue(value: BitArray)
  NullValue
  ListValue(value: List(GlitrValue))
  DictValue(value: dict.Dict(GlitrValue, GlitrValue))
  ObjectValue(value: List(#(String, GlitrValue)))
  OptionalValue(value: option.Option(GlitrValue))
  ResultValue(value: Result(GlitrValue, GlitrValue))
  EnumValue(variant: String, value: GlitrValue)
}

/// A converter is an object with the data necessary to encode and decode a specific Gleam type.  
/// You can build converters using the provided constructors.
pub opaque type Converter(a) {
  Converter(
    encoder: fn(a) -> GlitrValue,
    decoder: fn(GlitrValue) -> Result(a, List(decode.DecodeError)),
    type_def: GlitrType,
    // Temporary ugly stuff, while searching for a better solution
    default_value: a,
  )
}

/// Intermediate type to build a converter for an object type
pub opaque type PartialConverter(base) {
  PartialConverter(
    encoder: fn(base) -> GlitrValue,
    decoder: fn(GlitrValue) -> Result(base, List(decode.DecodeError)),
    fields_def: List(#(String, GlitrType)),
    // Temporary ugly stuff, while searching for a better solution
    default_value: Result(base, List(decode.DecodeError)),
  )
}

/// Create a Converter from a PartialConverter
/// 
/// Example:
/// ```
/// type Person {
///   Person(name: String, age: Int)
/// }
/// 
/// let convert = object({
///   use name <- field("name", fn(v: Person) { Ok(v.name) }, string())
///   use age <- field("age", fn(v: Person) { Ok(v.age) }, int())
///   success(Person(name:, age:))
/// })
/// ```
pub fn object(converter: PartialConverter(a)) -> Converter(a) {
  let assert Ok(default_value) = converter.default_value

  Converter(
    converter.encoder,
    converter.decoder,
    Object(converter.fields_def),
    default_value,
  )
}

/// Add a field to a PartialConverter  
/// See `object` for its usage details
/// 
/// 'field_name' is the field name that will be used in the converted value. It may not be equal to the actual field name.  
/// 'field_getter' is a function that returns the value of the field from the complete object.  
/// 'field_type' is a Converter associated to the type of the field.
pub fn field(
  field_name: String,
  field_getter: fn(c) -> Result(a, Nil),
  field_type: Converter(a),
  next: fn(a) -> PartialConverter(c),
) -> PartialConverter(c) {
  PartialConverter(
    encoder: fn(base: c) {
      let value = field_getter(base)

      case value {
        Error(Nil) -> NullValue
        Ok(field_value) -> {
          let converter = next(field_value)

          case converter.encoder(base) {
            ObjectValue(fields) ->
              ObjectValue([
                #(field_name, field_type.encoder(field_value)),
                ..fields
              ])
            _ -> NullValue
          }
        }
      }
    },
    decoder: fn(v: GlitrValue) {
      case v {
        ObjectValue(values) -> {
          let field_value =
            values
            |> list.key_find(field_name)
            |> result.replace_error([
              decode.DecodeError("Value", "None", [field_name]),
            ])
            |> result.then(field_type.decoder)

          use a <- result.try(field_value)

          next(a).decoder(v)
        }
        _ -> Error([])
      }
    },
    fields_def: {
      [
        #(field_name, field_type.type_def),
        ..next(field_type.default_value).fields_def
      ]
    },
    default_value: { next(field_type.default_value).default_value },
  )
}

/// Used to initialize a PartialConverter  
/// See `object` for its usage details
pub fn success(c: a) -> PartialConverter(a) {
  PartialConverter(fn(_) { ObjectValue([]) }, fn(_) { Ok(c) }, [], Ok(c))
}

/// Basic converter for a String value
pub fn string() -> Converter(String) {
  Converter(
    fn(v: String) { StringValue(v) },
    fn(v: GlitrValue) {
      case v {
        StringValue(val) -> Ok(val)
        other -> Error([decode.DecodeError("StringValue", get_type(other), [])])
      }
    },
    String,
    "",
  )
}

/// Basic converter for a Bool value
pub fn bool() -> Converter(Bool) {
  Converter(
    fn(v: Bool) { BoolValue(v) },
    fn(v: GlitrValue) {
      case v {
        BoolValue(val) -> Ok(val)
        other -> Error([decode.DecodeError("BoolValue", get_type(other), [])])
      }
    },
    Bool,
    False,
  )
}

/// Basic converter for a Float value
pub fn float() -> Converter(Float) {
  Converter(
    fn(v: Float) { FloatValue(v) },
    fn(v: GlitrValue) {
      case v {
        FloatValue(val) -> Ok(val)
        other -> Error([decode.DecodeError("FloatValue", get_type(other), [])])
      }
    },
    Float,
    0.0,
  )
}

/// Basic converter for a Int value
pub fn int() -> Converter(Int) {
  Converter(
    fn(v: Int) { IntValue(v) },
    fn(v: GlitrValue) {
      case v {
        IntValue(val) -> Ok(val)
        other -> Error([decode.DecodeError("IntValue", get_type(other), [])])
      }
    },
    Int,
    0,
  )
}

/// Basic converter for Dynamic values
pub fn dynamic() -> Converter(dynamic.Dynamic) {
  Converter(
    fn(v: dynamic.Dynamic) { DynamicValue(v) },
    fn(v: GlitrValue) {
      case v {
        DynamicValue(val) -> Ok(val)
        other ->
          Error([decode.DecodeError("DynamicValue", get_type(other), [])])
      }
    },
    Dynamic,
    dynamic.nil(),
  )
}

/// Basic converter for BitArray values
pub fn bit_array() -> Converter(BitArray) {
  Converter(
    fn(v: BitArray) { BitArrayValue(v) },
    fn(v: GlitrValue) {
      case v {
        BitArrayValue(val) -> Ok(val)
        other ->
          Error([decode.DecodeError("BitArrayValue", get_type(other), [])])
      }
    },
    BitArray,
    <<>>,
  )
}

/// Basic converter for a Nil value
pub fn null() -> Converter(Nil) {
  Converter(
    fn(_: Nil) { NullValue },
    fn(v: GlitrValue) {
      case v {
        NullValue -> Ok(Nil)
        other -> Error([decode.DecodeError("NullValue", get_type(other), [])])
      }
    },
    Null,
    Nil,
  )
}

/// Basic converter for a List value.   
/// 
/// `of` is a converter for the type of the elements.
pub fn list(of: Converter(a)) -> Converter(List(a)) {
  Converter(
    fn(v: List(a)) { ListValue(v |> list.map(of.encoder)) },
    fn(v: GlitrValue) {
      case v {
        ListValue(vals) ->
          vals
          |> list.fold(Ok([]), fn(result, val) {
            case result, of.decoder(val) {
              Ok(res), Ok(new_res) -> Ok(list.append(res, [new_res]))
              Error(errs), Error(new_errs) -> Error(list.append(errs, new_errs))
              _, Error(errs) | Error(errs), _ -> Error(errs)
            }
          })
        other -> Error([decode.DecodeError("ListValue", get_type(other), [])])
      }
    },
    List(of.type_def),
    [],
  )
}

/// Basic converter for a Option value.
/// 
/// `of` is a converter for the optional value.
pub fn optional(of: Converter(a)) -> Converter(option.Option(a)) {
  Converter(
    fn(v: option.Option(a)) { OptionalValue(v |> option.map(of.encoder)) },
    fn(v: GlitrValue) {
      case v {
        OptionalValue(option.None) -> Ok(option.None)
        OptionalValue(option.Some(val)) ->
          val |> of.decoder |> result.map(option.Some)
        other ->
          Error([decode.DecodeError("OptionalValue", get_type(other), [])])
      }
    },
    Optional(of.type_def),
    option.None,
  )
}

/// Basic converter for a Result value.
/// 
/// `res` is a converter for the Ok value.
/// `error` is a converter for the Error value.
pub fn result(
  res: Converter(ok),
  error: Converter(err),
) -> Converter(Result(ok, err)) {
  Converter(
    fn(v: Result(ok, err)) {
      ResultValue(
        v |> result.map(res.encoder) |> result.map_error(error.encoder),
      )
    },
    fn(v: GlitrValue) {
      case v {
        ResultValue(Ok(val)) -> val |> res.decoder |> result.map(Ok)
        ResultValue(Error(val)) -> val |> error.decoder |> result.map(Error)
        other -> Error([decode.DecodeError("ResultValue", get_type(other), [])])
      }
    },
    Result(res.type_def, error.type_def),
    Ok(res.default_value),
  )
}

/// Basic converter for a Dict value.
/// 
/// `key` is a converter for the keys.
/// `value` is a converter for the values.
/// 
/// Example:
/// ```
/// let converter: Converter(Dict(String, Int)) = dict(string(), int())
/// ```
pub fn dict(
  key: Converter(k),
  value: Converter(v),
) -> Converter(dict.Dict(k, v)) {
  Converter(
    fn(v: dict.Dict(k, v)) {
      DictValue(
        v
        |> dict.to_list
        |> list.map(fn(kv) { #(kv.0 |> key.encoder, kv.1 |> value.encoder) })
        |> dict.from_list,
      )
    },
    fn(v: GlitrValue) {
      case v {
        DictValue(d) ->
          d
          |> dict.to_list
          |> list.fold(Ok([]), fn(result, kv) {
            case result, key.decoder(kv.0), value.decoder(kv.1) {
              Ok(values), Ok(new_k), Ok(new_v) ->
                Ok(list.append(values, [#(new_k, new_v)]))
              Error(errs), Ok(_), Ok(_)
              | Ok(_), Ok(_), Error(errs)
              | Ok(_), Error(errs), Ok(_)
              -> Error(errs)
              Ok(_), Error(errs_1), Error(errs_2)
              | Error(errs_1), Error(errs_2), Ok(_)
              | Error(errs_1), Ok(_), Error(errs_2)
              -> Error(list.append(errs_1, errs_2))
              Error(errs), Error(errs_k), Error(errs_v) ->
                Error(list.flatten([errs, errs_k, errs_v]))
            }
          })
          |> result.map(dict.from_list)
        other -> Error([decode.DecodeError("DictValue", get_type(other), [])])
      }
    },
    Dict(key.type_def, value.type_def),
    dict.new(),
  )
}

/// Create a converter for an enum type
/// 
/// `tags` is a function that associate a tag to each variant of the enum
/// `converters` is a list of converters, each associated with a tag
/// 
/// Example:
/// ```
/// type Action {
///   Open(id: String)
///   Close(id: String)
/// }
/// 
/// let open_converter = object({
///   use id <- field("id", fn(v: Action) {
///     case v {
///       Open(id) -> Ok(id)
///       _ -> Error(Nil)
///     }
///   }, string())
///   success(Open(id:))
/// })
/// 
/// let close_converter = object({
///   use id <- field("id", fn(v: Action) {
///     case v {
///       Close(id) -> Ok(id)
///       _ -> Error(Nil)
///     }
///   }, string())
///   success(Close(id:))
/// })
/// 
/// let action_converter = enum(
///   fn(v) {
///     case v {
///       Open(_) -> "Open"
///       Close(_) -> "Close"
///     }
///   },
///   [
///     #("Open", open_converter),
///     #("Close", close_converter),
///   ]
/// )
/// ```
pub fn enum(
  tags: fn(a) -> String,
  converters: List(#(String, Converter(a))),
) -> Converter(a) {
  Converter(
    fn(v: a) {
      let tag = tags(v)

      case converters |> list.key_find(tag) {
        Ok(variant) -> EnumValue(tag, variant.encoder(v))
        Error(_) -> NullValue
      }
    },
    fn(v: GlitrValue) {
      case v {
        EnumValue(variant_name, value) -> {
          use variant <- result.try(
            converters
            |> list.key_find(variant_name)
            |> result.replace_error([
              decode.DecodeError(
                "One of: "
                  <> converters |> list.map(fn(v) { v.0 }) |> string.join("/"),
                variant_name,
                ["0"],
              ),
            ]),
          )
          variant.decoder(value)
        }
        other -> Error([decode.DecodeError("EnumValue", get_type(other), [])])
      }
    },
    Enum(converters |> list.map(fn(var) { #(var.0, { var.1 }.type_def) })),
    {
      let assert [first, ..] = converters
      { first.1 }.default_value
    },
  )
}

/// Create a converter by mapping the encode and decode functions from an existing one
/// 
/// Example:
/// ```
/// pub type Date {
///   Date(year: Int, month: Int, day: Int)
/// }
/// 
/// // We are storing the date as a string for optimized memory storage
/// pub fn date_converter() -> Converter(Date) {
///   string()
///   |> map(
///     fn(v: Date) { [v.year, v.month, v.day] |> list.map(int.to_string) |> string.join("/") },
///     fn(v: String) { 
///       let elems = string.split(v, "/")
///       case elems {
///         [y, m, d, ..] -> Ok(Date(y, m, d))
///         _ -> Error([])
///       },
///       Date(0, 0, 0) // This is required for now...
///     }
///   )
/// }
/// ```
pub fn map(
  converter: Converter(a),
  encode_map: fn(b) -> a,
  decode_map: fn(a) -> Result(b, List(decode.DecodeError)),
  default_value: b,
  // Kinda required until I find a more elegant way around this
) -> Converter(b) {
  Converter(
    fn(v: b) {
      let a_value = encode_map(v)
      converter.encoder(a_value)
    },
    fn(v: GlitrValue) {
      converter.decoder(v)
      |> result.then(decode_map)
    },
    converter.type_def,
    default_value,
  )
}

fn get_type(val: GlitrValue) -> String {
  case val {
    BoolValue(_) -> "BoolValue"
    DictValue(_) -> "DictValue"
    EnumValue(_, _) -> "EnumValue"
    FloatValue(_) -> "FloatValue"
    IntValue(_) -> "IntValue"
    DynamicValue(_) -> "DynamicValue"
    BitArrayValue(_) -> "BitArrayValue"
    ListValue(_) -> "ListValue"
    NullValue -> "NullValue"
    ObjectValue(_) -> "ObjectValue"
    OptionalValue(_) -> "OptionalValue"
    ResultValue(_) -> "ResultValue"
    StringValue(_) -> "StringValue"
  }
}

/// Encode a value into the corresponding GlitrValue using the converter.  
/// If the converter isn't valid, a NullValue is returned.
pub fn encode(converter: Converter(a)) -> fn(a) -> GlitrValue {
  converter.encoder
}

/// Decode a GlitrValue using the provided converter.
pub fn decode(
  converter: Converter(a),
) -> fn(GlitrValue) -> Result(a, List(decode.DecodeError)) {
  converter.decoder
}

/// Return the GlitrType associated with the converter
pub fn type_def(converter: Converter(a)) -> GlitrType {
  converter.type_def
}

/// Retrieve the default value associated with a converter.
/// 
/// This value is used as a fallback when decoding fails,
/// especially when building decoders that must return a value
/// even in the presence of errors.
///
/// ## Example
/// ```
/// let string_conv = string()
/// let default = default_value(string_conv)
/// // default == ""
/// ```
pub fn default_value(conv: Converter(a)) -> a {
  let Converter(_, _, _, default) = conv
  default
}
