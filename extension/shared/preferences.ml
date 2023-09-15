open Ext

let storage = Browser.storage |> Storage.local

type t = { port : int }

let load () =
  let open Lwt.Syntax in
  let+ port = Storage.Area.get storage "port" in
  let port = if Jv.is_undefined port then Defaults.port else Jv.to_int port in
  { port }

let save t =
  let open Lwt.Syntax in
  let port = Jv.of_int t.port in
  let+ _ = Storage.Area.set storage "port" port in
  ()
