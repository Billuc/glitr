import glitr/convert

pub type Field(db_type) {
  Field(name: String, converter: convert.Converter(db_type))
}

pub type Date {
  Date(year: Int, month: Int, day: Int)
}

pub type Time {
  Time(hour: Int, minute: Int, second: Int)
}

pub type Timestamp {
  Timestamp(date: Date, time: Time)
}
