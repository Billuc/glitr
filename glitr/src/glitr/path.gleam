import gleam/bool
import gleam/list

// pub type PathType(path_type) {
//   StaticPath(path: List(String))
//   ComplexPath(converter: PathConverter(path_type))
// }

pub type PathType {
  StaticPath
  ComplexPath
}

pub type PathConverter(path_type) {
  PathConverter(
    encoder: fn(path_type) -> List(String),
    decoder: fn(List(String)) -> Result(path_type, Nil),
  )
}

pub opaque type RoutePath(path_type) {
  RoutePath(ptype: PathType, converter: PathConverter(path_type))
}

pub fn static_path(root: List(String)) -> RoutePath(Nil) {
  RoutePath(
    StaticPath,
    PathConverter(
      fn(_) { root },
      //
      fn(path) {
        use <- bool.guard(path == root, Ok(Nil))
        Error(Nil)
      },
    ),
  )
}

pub fn id_path(root: List(String)) -> RoutePath(String) {
  RoutePath(
    ComplexPath,
    PathConverter(
      fn(id) { list.append(root, [id]) },
      //
      fn(segs) {
        let reverse_root = list.reverse(root)
        case list.reverse(segs) {
          [id, ..rest] if rest == reverse_root -> Ok(id)
          _ -> Error(Nil)
        }
      },
    ),
  )
}

pub fn complex_path(converter: PathConverter(p)) -> RoutePath(p) {
  RoutePath(ComplexPath, converter)
}

pub fn encode(path: RoutePath(a), value: a) -> List(String) {
  value |> path.converter.encoder
}

pub fn decode(path: RoutePath(a), value: List(String)) -> Result(a, Nil) {
  value |> path.converter.decoder
}

pub fn get_type(path: RoutePath(_)) -> PathType {
  path.ptype
}
