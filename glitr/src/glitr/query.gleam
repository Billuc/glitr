// pub type QueryType(query_type) {
//   EmptyQuery
//   ComplexQuery(converter: QueryConverter(query_type))
// }

pub type QueryType {
  EmptyQuery
  ComplexQuery
}

pub type QueryConverter(query_type) {
  QueryConverter(
    encoder: fn(query_type) -> List(#(String, String)),
    decoder: fn(List(#(String, String))) -> Result(query_type, Nil),
  )
}

pub opaque type RouteQuery(query_type) {
  RouteQuery(qtype: QueryType, converter: QueryConverter(query_type))
}

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

pub fn complex_query(converter: QueryConverter(q)) -> RouteQuery(q) {
  RouteQuery(ComplexQuery, converter)
}

pub fn encode(query: RouteQuery(q), value: q) -> List(#(String, String)) {
  value |> query.converter.encoder
}

pub fn decode(
  query: RouteQuery(q),
  value: List(#(String, String)),
) -> Result(q, Nil) {
  value |> query.converter.decoder
}

pub fn get_type(query: RouteQuery(_)) -> QueryType {
  query.qtype
}
