import envoy
import gleam/dynamic
import gleam/list
import gleam/result
import glitr/migrate/exec
import glitr/migrate/files
import glitr/migrate/types
import pog

const migration_zero = types.Migration(
  "",
  0,
  "CreateMigrationsTable",
  [
    "CREATE TABLE IF NOT EXISTS _migrations(
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    appliedAt TIMESTAMP NOT NULL DEFAULT NOW()
);",
  ],
  [],
)

const query_last_applied_migration = "SELECT id FROM _migrations ORDER BY appliedAt DESC LIMIT 1;"

pub fn migrate_up() -> Result(Nil, types.MigrateError) {
  use conn <- result.try(db_connect())
  use _ <- result.try(
    exec.exec_migration_up(conn, migration_zero)
    |> result.map_error(types.PGOTransactionError),
  )
  use last <- result.try(get_last_applied_migration(conn))

  use migrations <- files.get_migrations()

  use migration <- result.try(
    list.find(migrations, fn(m) { m.number == last + 1 })
    |> result.replace_error(types.MigrationNotFoundError(last + 1)),
  )
  use _ <- result.try(
    exec.exec_migration_up(conn, migration)
    |> result.map_error(types.PGOTransactionError),
  )
  use url <- result.try(get_db_url())
  use schema <- result.try(
    exec.get_schema(url) |> result.map_error(types.SchemaQueryError),
  )
  files.write_schema_file(schema)
}

pub fn migrate_down() -> Result(Nil, types.MigrateError) {
  use conn <- result.try(db_connect())
  use _ <- result.try(
    exec.exec_migration_up(conn, migration_zero)
    |> result.map_error(types.PGOTransactionError),
  )
  use last <- result.try(get_last_applied_migration(conn))

  use migrations <- files.get_migrations()

  use migration <- result.try(
    list.find(migrations, fn(m) { m.number == last })
    |> result.replace_error(types.MigrationNotFoundError(last)),
  )
  use _ <- result.try(
    exec.exec_migration_down(conn, migration)
    |> result.map_error(types.PGOTransactionError),
  )
  use url <- result.try(get_db_url())
  use schema <- result.try(
    exec.get_schema(url) |> result.map_error(types.SchemaQueryError),
  )
  files.write_schema_file(schema)
}

fn db_connect() -> Result(pog.Connection, types.MigrateError) {
  use url <- result.try(get_db_url())
  use config <- result.try(get_db_config(url))
  config |> pog.connect |> Ok
}

fn get_db_url() -> Result(String, types.MigrateError) {
  envoy.get("DATABASE_URL")
  |> result.replace_error(types.EnvVarError("DATABASE_URL"))
}

fn get_db_config(url: String) -> Result(pog.Config, types.MigrateError) {
  pog.url_config(url)
  |> result.replace_error(types.UrlError(url))
}

fn get_last_applied_migration(
  conn: pog.Connection,
) -> Result(Int, types.MigrateError) {
  pog.query(query_last_applied_migration)
  |> pog.returning(dynamic.element(0, dynamic.int))
  |> pog.execute(conn)
  |> result.map_error(types.PGOQueryError)
  |> result.then(fn(returned) {
    case returned {
      pog.Returned(0, _) | pog.Returned(_, []) -> Error(types.NoResultError)
      pog.Returned(_, [last, ..]) -> Ok(last)
    }
  })
}
