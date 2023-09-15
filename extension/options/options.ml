open Shared
open Ext

let main () =
  let open Lwt.Syntax in
  let* prefs = Preferences.load () in
  let port_field = Document.lookup_by_id "port" in
  Element.set_value port_field (Int.to_string prefs.port);
  let form = Document.lookup_by_id "prefs" in
  let _ =
    Brr.Ev.listen Brr_io.Form.Ev.submit
      (fun ev ->
        Brr.Ev.prevent_default ev;
        match Element.value_int port_field with
        | None -> ()
        | Some port ->
            Js_of_ocaml_lwt.Lwt_js_events.async @@ fun () ->
            Preferences.(save { port }))
      (Brr.El.as_target form)
  in

  Lwt.return ()

let () =
  Document.on_content_loaded @@ fun _ ->
  Js_of_ocaml_lwt.Lwt_js_events.async main
