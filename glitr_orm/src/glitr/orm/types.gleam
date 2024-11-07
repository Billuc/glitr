import gleam/option

pub type Table {
  Table(name: String, columns: List(Column))
}

pub type TableRef {
  TableRef(table: Table)
  SelfRef
}

pub type Column {
  Column(
    name: String,
    type_: ColumnType,
    primary_key: Bool,
    auto_increment: Bool,
    unique: Bool,
    nullable: Bool,
    default: option.Option(String),
    foreign_key: option.Option(Reference),
  )
}

pub type ColumnType {
  Varchar(size: Int)
  Boolean
  Integer
  Real
  DoublePrecision
  Date
  Time
  Timestamp
}

pub type Reference {
  Reference(
    table: TableRef,
    column: Column,
    on_delete: OnDeleteUpdateOption,
    on_update: OnDeleteUpdateOption,
  )
}

pub type OnDeleteUpdateOption {
  Cascade
  SetNull
  NoAction
}
