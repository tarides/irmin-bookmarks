open Shared
open Lwt.Syntax

type connected = { client : Client.t }
type loaded = { client : Client.t; items : Model.t list }
type t = Error of string | Connected of connected | Loaded of loaded

let msg c err =
  Brr.El.(div ~at:[ Brr.At.class' (Jstr.v c) ] [ txt (Jstr.v err) ])

let bookmark ~on_remove (model : Model.t) =
  let h2 =
    let href = Brr.At.href (Jstr.v model.url) in
    Brr.El.(h2 [ a ~at:[ href ] [ txt (Jstr.v model.name) ] ])
  in
  let notes = Brr.El.(p [ txt (Jstr.v model.notes) ]) in
  let created =
    Brr.El.(div [ txt (Date.of_ms model.created_at |> Date.pp_locale) ])
  in
  let rm_btn =
    let btn =
      Brr.El.(
        a
          ~at:Brr.At.[ href (Jstr.v "#"); class' (Jstr.v "delete") ]
          [ txt (Jstr.v "delete") ])
    in
    let _ =
      Element.bind_on_click btn @@ fun _ ->
      Js_of_ocaml_lwt.Lwt_js_events.async on_remove
    in
    btn
  in
  let meta =
    Brr.El.(div ~at:[ Brr.At.class' (Jstr.v "meta") ] [ created; rm_btn ])
  in
  if String.length model.notes = 0 then Brr.El.div [ h2; meta ]
  else Brr.El.div [ h2; notes; meta ]

let rec render t =
  let+ elems =
    match t with
    | Error e -> Lwt.return [ msg "error" e ]
    | Connected { client } ->
        let () =
          Js_of_ocaml_lwt.Lwt_js_events.async @@ fun () ->
          let* items = Client.list client in
          render (Loaded { client; items })
        in
        Lwt.return [ msg "info" "Loading..." ]
    | Loaded loaded ->
        let { items; client; _ } = loaded in
        let sort (a : Model.t) (b : Model.t) =
          Float.compare b.created_at a.created_at
        in
        let items =
          items
          |> List.sort sort
          |> List.map (fun (m : Model.t) ->
                 bookmark
                   ~on_remove:(fun () ->
                     let* _ = Client.delete client m in
                     let items =
                       List.filter (fun m' -> not (Model.equal m m')) items
                     in
                     render (Loaded { loaded with items }))
                   m)
        in
        let header =
          [ Brr.El.(h1 [ txt (Jstr.v "Bookmarks") ]); Brr.El.hr () ]
        in
        let wrapper =
          Brr.El.(div ~at:[ Brr.At.id (Jstr.v "bookmarks") ] items)
        in
        header @ [ wrapper ] |> Lwt.return
  in

  let ui = Document.lookup_by_id "ui" in
  let _ =
    elems
    |> List.map Brr.El.to_jv
    |> Array.of_list
    |> Jv.call (Brr.El.to_jv ui) "replaceChildren"
  in
  ()

let bind (client : Client.connect_result) =
  let t =
    match client with
    | Error msg -> Error msg
    | Ok client -> Connected { client }
  in
  render t
