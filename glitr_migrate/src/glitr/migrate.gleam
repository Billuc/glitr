import argv
import gleam/int
import gleam/io
import gleam/result
import glitr/migrate/commands
import glitr/migrate/types

pub fn main() {
  case argv.load().arguments {
    ["show"] -> commands.show()
    ["up"] -> commands.migrate_up()
    ["down"] -> commands.migrate_down()
    [x] ->
      case int.parse(x) {
        Error(_) -> show_usage()
        Ok(mig) -> commands.migrate_to(mig)
      }
    _ -> show_usage()
  }
  |> result.map_error(types.print_migrate_error)
}

fn show_usage() -> Result(Nil, types.MigrateError) {
  io.println("=======================================")
  io.println("=            GLITR MIGRATE            =")
  io.println("=======================================")
  io.println("")
  io.println("Usage: gleam run -m glitr/migrate [command|num]")
  io.println("")
  io.println("List of commands:")
  io.println(" - show:  Show the last currently applied migration")
  io.println(" - up:    Migrate up one version / Apply one migration")
  io.println(" - down:  Migrate down one version / Rollback one migration")
  io.println("")
  io.println(
    "Alternatively, a migration number can be passed and all migration between the currently",
  )
  io.println(
    "applied migration and the migration with the provided number will be applied/rolled back",
  )

  Ok(Nil)
}
