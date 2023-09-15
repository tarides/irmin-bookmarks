open Shared
open Ext

let main () =
  let open Lwt.Syntax in
  let* client = Client.connect () in
  Ui.bind client

let () =
  Document.on_content_loaded @@ fun _ ->
  Js_of_ocaml_lwt.Lwt_js_events.async main
