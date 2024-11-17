import envoy
import gleam/io
import gleam/result
import globlin
import globlin_fs
import simplifile

const migration_zero = "CREATE TABLE IF NOT EXISTS _migrations(
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    appliedAt TIMESTAMP NOT NULL,
);"

type MigrateError {
  EnvVarError(name: String)
  FileError(path: String)
  PatternError(error: String)
}

pub fn main() {
  todo
}

fn get_db_url(
  callback: fn(String) -> Result(a, MigrateError),
) -> Result(a, MigrateError) {
  envoy.get("DATABASE_URL")
  |> result.replace_error(EnvVarError("DATABASE_URL"))
  |> result.then(callback)
}

fn get_migrations(
  callback: fn(List(String)) -> Result(a, MigrateError),
) -> Result(a, MigrateError) {
  globlin.new_pattern("src/migrations/*.sql")
  |> result.replace_error(PatternError(
    "Something is wrong with the search pattern !",
  ))
  |> result.try(fn(pattern) {
    globlin_fs.glob(pattern, globlin_fs.RegularFiles)
    |> result.replace_error(FileError(
      "There was a problem accessing some files !",
    ))
  })
  |> result.try(callback)
}

fn 