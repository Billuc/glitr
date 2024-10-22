//// This module exports types and functions related to the path of Routes

import gleam/bool
import gleam/list

/// The type of path that can be expected from a Route
pub type PathType {
  StaticPath(root: List(String))
  ComplexPath
}

/// A wrapper for an encoder and a decoder to convert from request/response path to and from a Gleam type  
/// The decoder should return Error(Nil) if the input path doesn't correspond to the expected pattern
pub type PathConverter(path_type) {
  PathConverter(
    encoder: fn(path_type) -> List(String),
    decoder: fn(List(String)) -> Result(path_type, Nil),
  )
}

/// The path type of a Route
pub opaque type RoutePath(path_type) {
  RoutePath(ptype: PathType, converter: PathConverter(path_type))
}

/// Create a RoutePath that will solely match a static path
pub fn static_path(root: List(String)) -> RoutePath(Nil) {
  RoutePath(
    StaticPath(root),
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

/// Create a RoutePath that will match path of the type `/x/y/z/:id`
/// The id has to be the last segment of the path
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

/// Create a more complex RoutePath from a custom converter
pub fn complex_path(converter: PathConverter(p)) -> RoutePath(p) {
  RoutePath(ComplexPath, converter)
}

/// Encode a value using the RoutePath's encoder into path segments
pub fn encode(path: RoutePath(a), value: a) -> List(String) {
  value |> path.converter.encoder
}

/// Decode a value using the RoutePath's decoder from path segments
pub fn decode(path: RoutePath(a), value: List(String)) -> Result(a, Nil) {
  value |> path.converter.decoder
}

/// Return the PathType of a RoutePath
pub fn get_type(path: RoutePath(_)) -> PathType {
  path.ptype
}
