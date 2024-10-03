//// This module helps you create standard CRUD services routes

import gleam/dynamic
import gleam/http
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import glitr/body
import glitr/error
import glitr/path
import glitr/route
import glitr_convert/converter

/// The RouteService type  
/// Contains the data necessary to build the CRUD routes.
/// Note that all data transmission will be done via JSON objects.
pub type RouteService(base_type, upsert_type) {
  RouteService(
    root_path: List(String),
    base: Option(
      #(
        fn(base_type) -> json.Json,
        fn(dynamic.Dynamic) -> Result(base_type, List(dynamic.DecodeError)),
      ),
    ),
    upsert: Option(
      #(
        fn(upsert_type) -> json.Json,
        fn(dynamic.Dynamic) -> Result(upsert_type, List(dynamic.DecodeError)),
      ),
    ),
  )
}

/// Create a new empty service  
/// The base and upsert types will have to be specified !
pub fn new() -> RouteService(_, _) {
  RouteService([], None, None)
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
  RouteService(
    service.root_path,
    Some(#(base_encoder, base_decoder)),
    service.upsert,
  )
}

/// Specify the base type of a service by providing a glitr_convert type  
/// The base type of a service represent the type of object your service is associated with
pub fn with_base_type_converter(
  service: RouteService(_, _),
  converter: converter.Converter(base_type),
) -> RouteService(base_type, _) {
  RouteService(
    service.root_path,
    Some(#(
      fn(val) {
        converter |> converter.json_encode(val) |> result.unwrap(json.null())
        // Defaulting to null for now (should never happen though)
      },
      fn(val) { converter |> converter.json_decode(val) },
    )),
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
  RouteService(
    service.root_path,
    service.base,
    Some(#(upsert_encoder, upsert_decoder)),
  )
}

/// Specify the upsert type of a service by providing a glitr_convert type    
/// The upsert type of a service represent the type used to create or update objects of your service
pub fn with_upsert_type_converter(
  service: RouteService(_, _),
  converter: converter.Converter(upsert_type),
) -> RouteService(_, upsert_type) {
  RouteService(
    service.root_path,
    service.base,
    Some(#(
      fn(val) {
        converter |> converter.json_encode(val) |> result.unwrap(json.null())
        // Defaulting to null for now (should never happen though)
      },
      fn(val) { converter |> converter.json_decode(val) },
    )),
  )
}

/// Generate a create route associated with a service
pub fn create_route(
  service: RouteService(base_type, upsert_type),
) -> Result(route.Route(Nil, Nil, upsert_type, base_type), error.GlitrError) {
  case service.upsert, service.base {
    None, _ ->
      Error(error.RouteError(
        "No upsert type provided, make sure you called with_upsert_type",
      ))
    _, None ->
      Error(error.RouteError(
        "No base type provided, make sure you called with_base_type",
      ))
    Some(upsert), Some(base) -> {
      route.new()
      |> route.with_method(http.Post)
      |> route.with_path(path.static_path(service.root_path))
      |> route.with_request_body(body.json_body(upsert.0, upsert.1))
      |> route.with_response_body(body.json_body(base.0, base.1))
      |> Ok
    }
  }
}

/// Generate a get-all route associated with a service
pub fn get_all_route(
  service: RouteService(base_type, upsert_type),
) -> Result(route.Route(Nil, Nil, Nil, List(base_type)), error.GlitrError) {
  case service.base {
    None ->
      Error(error.RouteError(
        "No base type provided, make sure you called with_base_type",
      ))
    Some(base) -> {
      route.new()
      |> route.with_method(http.Get)
      |> route.with_path(path.static_path(service.root_path))
      |> route.with_response_body(body.json_body(
        fn(v) { v |> json.array(base.0) },
        dynamic.list(base.1),
      ))
      |> Ok
    }
  }
}

/// Generate a get route associated with a service
pub fn get_route(
  service: RouteService(base_type, upsert_type),
) -> Result(route.Route(String, Nil, Nil, base_type), error.GlitrError) {
  case service.base {
    None ->
      Error(error.RouteError(
        "No base body type provided, make sure you called with_base_type",
      ))
    Some(base) -> {
      route.new()
      |> route.with_method(http.Get)
      |> route.with_path(path.id_path(service.root_path))
      |> route.with_response_body(body.json_body(base.0, base.1))
      |> Ok
    }
  }
}

/// Generate a update route associated with a service
pub fn update_route(
  service: RouteService(base_type, upsert_type),
) -> Result(route.Route(String, Nil, upsert_type, base_type), error.GlitrError) {
  case service.upsert, service.base {
    None, _ ->
      Error(error.RouteError(
        "No upsert body type provided, make sure you called with_upsert_type",
      ))
    _, None ->
      Error(error.RouteError(
        "No base body type provided, make sure you called with_base_type",
      ))
    Some(upsert), Some(base) -> {
      route.new()
      |> route.with_method(http.Post)
      |> route.with_path(path.id_path(service.root_path))
      |> route.with_request_body(body.json_body(upsert.0, upsert.1))
      |> route.with_response_body(body.json_body(base.0, base.1))
      |> Ok
    }
  }
}

/// Generate a delete route associated with a service  
/// Note that the return is the id of the deleted instance
pub fn delete_route(
  service: RouteService(base_type, upsert_type),
) -> Result(route.Route(String, Nil, Nil, String), error.GlitrError) {
  route.new()
  |> route.with_method(http.Delete)
  |> route.with_path(path.id_path(service.root_path))
  |> route.with_response_body(body.json_body(json.string, dynamic.string))
  |> Ok
}
