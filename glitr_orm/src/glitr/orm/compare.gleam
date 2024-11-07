import glitr/orm/types

pub type SchemaDiff {
  TableName(from: String, to: String)
}

pub fn compare(table_from: types.Table, table_to: types.Table) {
  todo
}
