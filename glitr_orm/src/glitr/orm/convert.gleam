import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glitr/convert
import glitr/orm

const date_sep = "-"

const time_sep = ":"

pub fn date() -> convert.Converter(orm.Date) {
  convert.string()
  |> convert.map(date_to_str, str_to_date)
}

fn date_to_str(v: orm.Date) -> String {
  [v.year, v.month, v.day]
  |> list.map(int.to_string)
  |> string.join(date_sep)
}

fn str_to_date(v: String) -> orm.Date {
  let elems =
    string.split(v, date_sep)
    |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
  case elems {
    [y, m, d, ..] -> orm.Date(y, m, d)
    [y, m] -> orm.Date(y, m, -1)
    [y] -> orm.Date(y, -1, -1)
    [] -> orm.Date(-1, -1, -1)
  }
}

pub fn time() -> convert.Converter(orm.Time) {
  convert.string()
  |> convert.map(time_to_str, str_to_time)
}

fn time_to_str(v: orm.Time) -> String {
  [v.hour, v.minute, v.second]
  |> list.map(int.to_string)
  |> string.join(time_sep)
}

fn str_to_time(v: String) -> orm.Time {
  let elems =
    string.split(v, time_sep)
    |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
  case elems {
    [h, m, s, ..] -> orm.Time(h, m, s)
    [h, m] -> orm.Time(h, m, -1)
    [h] -> orm.Time(h, -1, -1)
    [] -> orm.Time(-1, -1, -1)
  }
}

pub fn timestamp() -> convert.Converter(orm.Timestamp) {
  convert.string()
  |> convert.map(
    fn(v: orm.Timestamp) {
      [date_to_str(v.date), time_to_str(v.time)] |> string.join(" ")
    },
    fn(v: String) {
      let elems = string.split(v, " ")
      case elems {
        [d, t, ..] -> orm.Timestamp(str_to_date(d), str_to_time(t))
        [d] -> orm.Timestamp(str_to_date(d), orm.Time(-1, -1, -1))
        [] -> orm.Timestamp(orm.Date(-1, -1, -1), orm.Time(-1, -1, -1))
      }
    },
  )
}
