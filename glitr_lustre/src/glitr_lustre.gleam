import glitr
import glitr/utils
import lustre/effect
import lustre_http

pub fn send_to_route(
  route: glitr.Route(p, req_b, res_b),
  path: p,
  body: req_b,
  as_msg: fn(Result(res_b, lustre_http.HttpError)) -> msg,
) -> effect.Effect(msg) {
  lustre_http.send(
    route |> utils.to_request(path, body),
    lustre_http.expect_json(route.res_body_converter.decoder, as_msg),
  )
}
