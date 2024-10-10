//// This module helps you create standard CRUD services routes
//// 
//// Example : 
//// ```
//// import glitr/service
//// import glitr/convert
//// 
//// pub type Todo {
////  Todo(id: String, title: String)
//// }
//// 
//// pub type UpsertTodo {
////  UpsertTodo(title: String)
//// }
//// 
//// pub fn todo_converter() -> convert.Converter(Todo) {
////  convert.object({
////    use id <- convert.parameter
////    use title <- convert.parameter
////    use <- convert.constructor
////    Todo(id:, title:)
////  })
////  |> convert.field("id", fn(v) { v.id }, convert.string())
////  |> convert.field("title", fn(v) { v.title }, convert.string())
////  |> convert.to_converter()
//// }
//// 
//// pub fn upsert_todo_converter() -> convert.Converter(UpsertTodo) {
////  convert.object({
////    use title <- convert.parameter
////    use <- convert.constructor
////    UpsertTodo(title:)
////  })
////  |> convert.field("title", fn(v) { v.title }, convert.string())
////  |> convert.to_converter()
//// }
//// 
//// pub fn todo_service() -> service.RouteService(Todo, UpsertTodo) {
////  service.new()
////  |> service.with_root_path(["todos"])
////  |> service.with_base_converter(todo_converter())
////  |> service.with_upsert_converter(upsert_todo_converter())
//// }
//// 
//// pub fn create_todo_route() {
////  todo_service() |> service.create_route()
//// }
//// ```

import gleam/dynamic
import gleam/http
import gleam/json
import glitr/body
import glitr/convert
import glitr/convert/json as glitr_json
import glitr/path
import glitr/route

/// The RouteService type  
/// Contains the data necessary to build the CRUD routes.
/// Note that all data transmission will be done via JSON objects.
pub type RouteService(base_type, upsert_type) {
  RouteService(
    root_path: List(String),
    base: #(
      fn(base_type) -> json.Json,
      fn(dynamic.Dynamic) -> Result(base_type, List(dynamic.DecodeError)),
    ),
    upsert: #(
      fn(upsert_type) -> json.Json,
      fn(dynamic.Dynamic) -> Result(upsert_type, List(dynamic.DecodeError)),
    ),
  )
}

fn nil_converter() {
  #(fn(_) { json.null() }, fn(_) { Ok(Nil) })
}

/// Create a new empty service  
/// The base and upsert types will have to be specified !
pub fn new() -> RouteService(Nil, Nil) {
  RouteService([], nil_converter(), nil_converter())
}

/// Change the root path of a service
pub fn with_root_path(
  service: RouteService(_, _),
  root_path: List(String),
) -> RouteService(_, _) {
  RouteService(..service, root_path: root_path)
}

/// Specify the base type of a service by providing a JSON encoder & decoder  
/// The base type of a service represent the type of object your service is associated with
pub fn with_base_type(
  service: RouteService(_, _),
  base_encoder: fn(base_type) -> json.Json,
  base_decoder: fn(dynamic.Dynamic) ->
    Result(base_type, List(dynamic.DecodeError)),
) -> RouteService(base_type, _) {
  RouteService(service.root_path, #(base_encoder, base_decoder), service.upsert)
}

/// Specify the base type of a service by providing a glitr_convert type  
/// The base type of a service represent the type of object your service is associated with
pub fn with_base_converter(
  service: RouteService(_, _),
  converter: convert.Converter(base_type),
) -> RouteService(base_type, _) {
  RouteService(
    service.root_path,
    #(
      fn(val) { val |> glitr_json.json_encode(converter) },
      glitr_json.json_decode(converter),
    ),
    service.upsert,
  )
}

/// Specify the upsert type of a service by providing a JSON encoder & decoder  
/// The upsert type of a service represent the type used to create or update objects of your service
pub fn with_upsert_type(
  service: RouteService(_, _),
  upsert_encoder: fn(upsert_type) -> json.Json,
  upsert_decoder: fn(dynamic.Dynamic) ->
    Result(upsert_type, List(dynamic.DecodeError)),
) -> RouteService(_, upsert_type) {
  RouteService(service.root_path, service.base, #(
    upsert_encoder,
    upsert_decoder,
  ))
}

/// Specify the upsert type of a service by providing a glitr_convert type    
/// The upsert type of a service represent the type used to create or update objects of your service
pub fn with_upsert_converter(
  service: RouteService(_, _),
  converter: convert.Converter(upsert_type),
) -> RouteService(_, upsert_type) {
  RouteService(service.root_path, service.base, #(
    fn(val) { val |> glitr_json.json_encode(converter) },
    glitr_json.json_decode(converter),
  ))
}

/// Generate a create route associated with a service
pub fn create_route(
  service: RouteService(base_type, upsert_type),
) -> route.Route(Nil, Nil, upsert_type, base_type) {
  route.new()
  |> route.with_method(http.Post)
  |> route.with_path(path.static_path(service.root_path))
  |> route.with_request_body(body.json_body(service.upsert.0, service.upsert.1))
  |> route.with_response_body(body.json_body(service.base.0, service.base.1))
}

/// Generate a get-all route associated with a service
pub fn get_all_route(
  service: RouteService(base_type, upsert_type),
) -> route.Route(Nil, Nil, Nil, List(base_type)) {
  route.new()
  |> route.with_method(http.Get)
  |> route.with_path(path.static_path(service.root_path))
  |> route.with_response_body(body.json_body(
    fn(v) { v |> json.array(service.base.0) },
    dynamic.list(service.base.1),
  ))
}

/// Generate a get route associated with a service
pub fn get_route(
  service: RouteService(base_type, upsert_type),
) -> route.Route(String, Nil, Nil, base_type) {
  route.new()
  |> route.with_method(http.Get)
  |> route.with_path(path.id_path(service.root_path))
  |> route.with_response_body(body.json_body(service.base.0, service.base.1))
}

/// Generate a update route associated with a service
pub fn update_route(
  service: RouteService(base_type, upsert_type),
) -> route.Route(String, Nil, upsert_type, base_type) {
  route.new()
  |> route.with_method(http.Post)
  |> route.with_path(path.id_path(service.root_path))
  |> route.with_request_body(body.json_body(service.upsert.0, service.upsert.1))
  |> route.with_response_body(body.json_body(service.base.0, service.base.1))
}

/// Generate a delete route associated with a service  
/// Note that the return is the id of the deleted instance
pub fn delete_route(
  service: RouteService(base_type, upsert_type),
) -> route.Route(String, Nil, Nil, String) {
  route.new()
  |> route.with_method(http.Delete)
  |> route.with_path(path.id_path(service.root_path))
  |> route.with_response_body(body.json_body(json.string, dynamic.string))
}
