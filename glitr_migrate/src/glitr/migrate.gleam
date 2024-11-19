import gleam/result
import glitr/migrate/commands
import glitr/migrate/types

pub fn main() {
  commands.migrate_up()
  |> result.map_error(types.print_migrate_error)
}
