import glance
import glance_printer
import gleam/int
import gleam/io
import gleam/list
import gleam/regex
import gleam/string
import gleam/string_builder
import shellout
import simplifile

pub const base_dir = "/src/orm"

const schema_path = base_dir <> "/schema.gleam"

pub const gen_dir = base_dir <> "/gen"

const gen_schema_path = gen_dir <> "/schema.gleam"

const gen_prev_schema_path = gen_dir <> "/schema_prev.gleam"

pub fn main() {
  let res_pwd = simplifile.current_directory()

  case res_pwd {
    Error(err) -> io.println_error(simplifile.describe_error(err))
    Ok(pwd) -> {
      let schema_content = read_schema_file(pwd)

      case schema_content {
        Error(err) -> io.println_error(simplifile.describe_error(err))
        Ok(content) -> render_schema_file(pwd, content)
      }

      let cmd_res =
        shellout.command(
          "gleam",
          [
            "run",
            "-m",
            gen_schema_path |> string.drop_left(5) |> string.drop_right(6),
          ],
          pwd <> "/",
          [],
        )
      case cmd_res {
        Ok(_) -> io.println("Success !")
        Error(_) -> io.println_error("Something went wrong !")
      }
    }
  }
}

fn read_schema_file(start_dir: String) -> Result(String, simplifile.FileError) {
  simplifile.read(start_dir <> schema_path)
}

fn find_tables(schema_content: String) -> List(String) {
  let assert Ok(table_regex) = regex.from_string("fn ([a-z]*)_table")

  let matches = regex.scan(table_regex, schema_content)
  list.map(matches, fn(m) { m.content |> string.drop_left(3) })
}

fn render_schema_file(pwd: String, schema_content: String) -> Nil {
  let _ = simplifile.create_directory(pwd <> gen_dir)
  let _ = simplifile.delete(pwd <> gen_prev_schema_path)
  render_base_schema_prev(pwd)
  let _ = simplifile.rename(pwd <> gen_schema_path, pwd <> gen_prev_schema_path)
  let _ = simplifile.delete(pwd <> gen_schema_path)
  let _ = simplifile.create_file(pwd <> gen_schema_path)

  let _ = simplifile.create_file(pwd <> gen_schema_path)
  let _ =
    simplifile.write(pwd <> gen_schema_path, render_schema(schema_content))
  Nil
}

fn render_base_schema_prev(pwd: String) -> Nil {
  let res_file = simplifile.is_file(pwd <> gen_prev_schema_path)

  case res_file {
    Error(err) -> io.println_error(simplifile.describe_error(err))
    Ok(True) -> Nil
    Ok(False) -> {
      let content = "pub fn tables() {\n\t[]\n}\n"
      let _ = simplifile.write(pwd <> gen_prev_schema_path, content)
      Nil
    }
  }
}

fn render_schema(schema_content: String) -> String {
  // Ugly, to change
  let schema_prev_path =
    gen_prev_schema_path
    |> string.drop_left(5)
    |> string.drop_right(6)
  let schema_prev_name =
    gen_prev_schema_path
    |> string.drop_left(string.length(gen_dir) + 1)
    |> string.drop_right(6)
  let tables = find_tables(schema_content)

  let content =
    string_builder.new()
    |> string_builder.append("import glitr/orm/compare\n")
    |> string_builder.append("import glitr/orm/render\n")
    |> string_builder.append("import ")
    |> string_builder.append(schema_prev_path)
    |> string_builder.append("\n")
    |> string_builder.append(schema_content)
    |> string_builder.append("\npub fn tables() {\n")
    |> string_builder.append(render_table_list(tables))
    |> string_builder.append("\n}\n\npub fn main() {\n")
    |> string_builder.append("\tlet changes = compare.compare(tables(), ")
    |> string_builder.append(schema_prev_name)
    |> string_builder.append(".tables())\n")
    |> string_builder.append("\trender.render_migration_file(changes)\n")
    |> string_builder.append("\trender.render_table_files(tables())\n")
    |> string_builder.append("}\n")
    |> string_builder.to_string

  let module = glance.module(content)

  case module {
    Error(err) -> {
      case err {
        glance.UnexpectedEndOfInput -> {
          io.println_error("Unexpected end of input\n\nContent:\n\n" <> content)
          ""
        }
        glance.UnexpectedToken(_token, pos) -> {
          io.println_error(
            "Unexpected token at position "
            <> int.to_string(pos.byte_offset)
            <> "\n\nContent:\n\n"
            <> content,
          )
          ""
        }
      }
    }
    Ok(m) -> glance_printer.print(m)
  }
}

fn render_table_list(tables: List(String)) {
  "\t["
  <> list.map(tables, fn(t) { t <> "()" })
  |> string.join(", ")
  <> "]"
}
