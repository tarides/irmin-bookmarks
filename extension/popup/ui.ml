open Shared
open Lwt.Syntax

type state = { client : Client.t; model : Model.t; error : string option }
type t = Disconnected of string | Connected of state | Loaded of state

let msg c err =
  Brr.El.(div ~at:[ Brr.At.class' (Jstr.v c) ] [ txt (Jstr.v err) ])

let header () =
  let view_all =
    Brr.El.(a ~at:[ Brr.At.href (Jstr.v "#") ] [ txt (Jstr.v "view all") ])
  in
  let _ =
    Element.bind_on_click view_all @@ fun _ ->
    let view_page = Browser.runtime |> Runtime.get_url "../view/index.html" in
    Lwt.async @@ fun () ->
    let+ _ = Browser.tabs |> Tabs.create view_page in
    Window.close ()
  in
  let h1 = Brr.El.(h1 [ txt (Jstr.v "Add Bookmark") ]) in
  let hr = Brr.El.hr () in
  Brr.El.header [ view_all; h1; hr ]

let form (model : Model.t) save =
  let name_id = Jstr.v "bm-name" in
  let name_label =
    Brr.El.(label ~at:[ Brr.At.for' name_id ] [ txt (Jstr.v "Name") ])
  in
  let name_input =
    Brr.El.(
      input
        ~at:
          Brr.At.
            [
              id name_id;
              name (Jstr.v "name");
              placeholder (Jstr.v "Bookmark name");
              type' (Jstr.v "text");
              v (Jstr.v "maxlength") (Jstr.v "255");
            ]
        ())
  in
  Element.set_value name_input model.name;

  let notes_id = Jstr.v "bm-notes" in
  let notes_label =
    Brr.El.(label ~at:[ Brr.At.for' notes_id ] [ txt (Jstr.v "Notes") ])
  in
  let notes =
    Brr.El.(
      textarea
        ~at:Brr.At.[ id notes_id; name (Jstr.v "notes") ]
        [ txt (Jstr.v model.notes) ])
  in

  let save_btn =
    Brr.El.(
      button
        ~at:Brr.At.[ id (Jstr.v "bm-save"); type' (Jstr.v "submit") ]
        [ txt (Jstr.v "Save") ])
  in
  let _ =
    Element.bind_on_click save_btn @@ fun _ ->
    let name = Element.value_string name_input in
    let notes = Element.value_string notes in
    let updated_at = Date.now () in
    let model = Model.update model ~updated_at ~name ~notes in
    save model
  in
  let buttons =
    Brr.El.(div ~at:[ Brr.At.id (Jstr.v "buttons") ] [ save_btn ])
  in
  [ name_label; name_input; notes_label; notes; buttons ]

let rec render t =
  let+ elems =
    match t with
    | Disconnected e -> Lwt.return [ msg "error" e ]
    | Connected { client; model; _ } ->
        let () =
          Lwt.async @@ fun () ->
          let* model =
            let+ saved_model = Client.load client model in
            match saved_model with None -> model | Some m -> m
          in
          render (Loaded { model; client; error = None })
        in
        Lwt.return [ msg "info" "Loading..." ]
    | Loaded { client; model; error } ->
        let ui =
          header ()
          :: form model (fun model ->
                 Lwt.async @@ fun () ->
                 let* r = Client.save client model in
                 match r with
                 | Ok _ -> Window.close () |> Lwt.return
                 | Error error ->
                     render (Loaded { error = Some error; model; client }))
        in
        (match error with None -> ui | Some err -> msg "error" err :: ui)
        |> Lwt.return
  in

  let ui = Document.lookup_by_id "ui" in
  let _ =
    elems
    |> List.map Brr.El.to_jv
    |> Array.of_list
    |> Jv.call (Brr.El.to_jv ui) "replaceChildren"
  in
  ()

let bind (client : Client.connect_result) model =
  let t =
    match client with
    | Ok client -> Connected { client; model; error = None }
    | Error msg -> Disconnected msg
  in
  render t
