//// This module exports types and functions related to the query of Routes

/// The type of query that can be expected from a Route
pub type QueryType {
  EmptyQuery
  ComplexQuery
}

/// A wrapper for an encoder and a decoder to convert from request/response query to and from a Gleam type
pub type QueryConverter(query_type) {
  QueryConverter(
    encoder: fn(query_type) -> List(#(String, String)),
    decoder: fn(List(#(String, String))) -> Result(query_type, Nil),
  )
}

/// The query type of a Route
pub opaque type RouteQuery(query_type) {
  RouteQuery(qtype: QueryType, converter: QueryConverter(query_type))
}

/// Create a RouteQuery that convert from/to an empty query
pub fn empty_query() -> RouteQuery(Nil) {
  RouteQuery(
    EmptyQuery,
    QueryConverter(
      fn(_) { [] },
      //
      fn(_) { Ok(Nil) },
    ),
  )
}

/// Create a more complex RouteQuery from a custom converter
pub fn complex_query(converter: QueryConverter(q)) -> RouteQuery(q) {
  RouteQuery(ComplexQuery, converter)
}

/// Encode a value using the RouteQuery's encoder into a query
pub fn encode(query: RouteQuery(q), value: q) -> List(#(String, String)) {
  value |> query.converter.encoder
}

/// Decode a value using the RouteQuery's decoder from a query
pub fn decode(
  query: RouteQuery(q),
  value: List(#(String, String)),
) -> Result(q, Nil) {
  value |> query.converter.decoder
}

/// Return the QueryType of a RouteQuery
pub fn get_type(query: RouteQuery(_)) -> QueryType {
  query.qtype
}
