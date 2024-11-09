import gleam/list
import gleam/result
import glitr/orm/types

pub type TableChange {
  NewColumn(column: types.Column)
  DropColumn(column: types.Column)
  // Change type non standard
  ChangeType(
    column: types.Column,
    type_from: types.ColumnType,
    type_to: types.ColumnType,
  )
}

pub type SchemaChange {
  NewTable(table: types.Table)
  DropTable(table: types.Table)
  TableChanges(table: String, changes: List(TableChange))
}

pub fn compare(
  tables_from: List(types.Table),
  tables_to: List(types.Table),
) -> List(SchemaChange) {
  list.append(
    get_dropped_or_modified_tables(tables_from, tables_to),
    get_created_tables(tables_from, tables_to),
  )
}

fn get_dropped_or_modified_tables(
  tables_from: List(types.Table),
  tables_to: List(types.Table),
) -> List(SchemaChange) {
  list.map(tables_from, fn(table_from) {
    let res_table_to = list.find(tables_to, fn(t) { t.name == table_from.name })

    case res_table_to {
      Error(Nil) -> Ok(DropTable(table_from))
      Ok(table_to) -> {
        case compare_tables(table_from, table_to) {
          [] -> Error(Nil)
          changes -> Ok(TableChanges(table_from.name, changes))
        }
      }
    }
  })
  |> result.values
}

fn get_created_tables(
  tables_from: List(types.Table),
  tables_to: List(types.Table),
) -> List(SchemaChange) {
  list.map(tables_to, fn(table_to) {
    let res_table_from =
      list.find(tables_from, fn(t) { t.name == table_to.name })

    case res_table_from {
      Error(Nil) -> Ok(NewTable(table_to))
      Ok(_table_from) -> Error(Nil)
    }
  })
  |> result.values
}

fn compare_tables(
  table_from: types.Table,
  table_to: types.Table,
) -> List(TableChange) {
  list.append(
    get_dropped_or_altered_columns(table_from.columns, table_to.columns),
    get_created_columns(table_from.columns, table_to.columns),
  )
}

fn get_dropped_or_altered_columns(
  cols_from: List(types.Column),
  cols_to: List(types.Column),
) -> List(TableChange) {
  list.map(cols_from, fn(col_from) {
    let res_col_to = list.find(cols_to, fn(c) { c.name == col_from.name })

    case res_col_to {
      Error(Nil) -> Ok(DropColumn(col_from))
      Ok(col_to) -> compare_columns(col_from, col_to)
    }
  })
  |> result.values
}

fn get_created_columns(
  cols_from: List(types.Column),
  cols_to: List(types.Column),
) -> List(TableChange) {
  list.map(cols_to, fn(col_to) {
    let res_col_from = list.find(cols_from, fn(c) { c.name == col_to.name })

    case res_col_from {
      Error(Nil) -> Ok(NewColumn(col_to))
      Ok(_col_from) -> Error(Nil)
    }
  })
  |> result.values
}

fn compare_columns(
  _col_from: types.Column,
  _col_to: types.Column,
) -> Result(TableChange, Nil) {
  // Do nothing for now
  Error(Nil)
}
