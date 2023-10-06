open Shared

let main () =
  let open Lwt.Syntax in
  let* client = Client.connect () in
  Ui.bind client

let () = Document.on_content_loaded @@ fun _ -> Lwt.async main
