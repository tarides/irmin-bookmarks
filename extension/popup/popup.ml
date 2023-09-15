open Shared
open Ext

let main () =
  let open Lwt.Syntax in
  let* tab = Browser.tabs |> Tabs.active in
  let model =
    let name = Tab.title tab in
    let url = Tab.url tab in
    let created_at = Date.now () in
    Model.v ~created_at ~name ~url ~notes:""
  in
  let* client = Client.connect () in
  Ui.bind client model

let () =
  Document.on_content_loaded @@ fun _ ->
  Js_of_ocaml_lwt.Lwt_js_events.async main
