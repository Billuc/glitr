import gleam/option
import glitr/orm/types

pub fn define_table(name: String, columns: List(types.Column)) -> types.Table {
  types.Table(name, columns)
}

pub fn varchar(name: String, size: Int) -> types.Column {
  types.Column(
    name,
    types.Varchar(size),
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn boolean(name: String) -> types.Column {
  types.Column(
    name,
    types.Boolean,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn integer(name: String) -> types.Column {
  types.Column(
    name,
    types.Integer,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn real(name: String) -> types.Column {
  types.Column(
    name,
    types.Real,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn double(name: String) -> types.Column {
  types.Column(
    name,
    types.DoublePrecision,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn date(name: String) -> types.Column {
  types.Column(
    name,
    types.Date,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn time(name: String) -> types.Column {
  types.Column(
    name,
    types.Time,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn timestamp(name: String) -> types.Column {
  types.Column(
    name,
    types.Timestamp,
    False,
    False,
    False,
    True,
    option.None,
    option.None,
  )
}

pub fn primary_key(column: types.Column, auto_increment: Bool) -> types.Column {
  types.Column(..column, primary_key: True, auto_increment:)
}

pub fn not_null(column: types.Column) -> types.Column {
  types.Column(..column, nullable: False)
}

pub fn unique(column: types.Column) -> types.Column {
  types.Column(..column, unique: True)
}

pub fn default(column: types.Column, default_value: String) -> types.Column {
  types.Column(..column, default: option.Some(default_value))
}

pub fn foreign_key(
  column: types.Column,
  table: types.TableRef,
  foreign_column: types.Column,
) -> types.Column {
  types.Column(
    ..column,
    foreign_key: option.Some(types.Reference(
      table,
      foreign_column,
      types.NoAction,
      types.NoAction,
    )),
  )
}

pub fn on_delete(
  column: types.Column,
  action: types.OnDeleteUpdateOption,
) -> types.Column {
  case column.foreign_key {
    option.None -> column
    option.Some(fk) ->
      types.Column(
        ..column,
        foreign_key: option.Some(types.Reference(..fk, on_delete: action)),
      )
  }
}

pub fn on_update(
  column: types.Column,
  action: types.OnDeleteUpdateOption,
) -> types.Column {
  case column.foreign_key {
    option.None -> column
    option.Some(fk) ->
      types.Column(
        ..column,
        foreign_key: option.Some(types.Reference(..fk, on_update: action)),
      )
  }
}
