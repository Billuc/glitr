import gleam/dict
import gleam/option

/// This type is used to define the shape of the data.  
/// It isn't meant to be used directly !  
/// It is better to use converters that use GlitrTypes internally to decode data.
pub type GlitrType {
  String
  Bool
  Float
  Int
  Null
  List(of: GlitrType)
  Dict(key: GlitrType, value: GlitrType)
  Object(fields: List(#(String, GlitrType)))
  Optional(of: GlitrType)
  Result(result: GlitrType, error: GlitrType)
  Enum(variants: List(#(String, GlitrType)))
  // Maybe add BitArray
}

/// This type is used to represent data values.  
/// It is an intermediate type between encoded data and Gleam types.
/// It isn't meant to be used directly !  
pub type GlitrValue {
  StringValue(value: String)
  BoolValue(value: Bool)
  FloatValue(value: Float)
  IntValue(value: Int)
  NullValue
  ListValue(value: List(GlitrValue))
  DictValue(value: dict.Dict(GlitrValue, GlitrValue))
  ObjectValue(value: List(#(String, GlitrValue)))
  OptionalValue(value: option.Option(GlitrValue))
  ResultValue(value: Result(GlitrValue, GlitrValue))
  EnumValue(variant: String, value: GlitrValue)
}
