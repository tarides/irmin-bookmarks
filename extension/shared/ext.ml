(** Bindings to browser/extension APIs + APIs for our extension *)

module Jv_lwt = struct
  let of_promise ~(ok : Jv.t -> 'a) (p : Jv.Promise.t) : 'a Lwt.t =
    let promise, resolver = Lwt.wait () in
    let _ =
      Jv.Promise.then' p
        (fun v ->
          Lwt.wakeup_later resolver (ok v);
          Jv.Promise.resolve ())
        (fun e ->
          Lwt.wakeup_exn resolver (Jv.Error e);
          Jv.Promise.resolve ())
    in
    promise
end

module Date = struct
  let t = Jv.get Jv.global "Date"
  let now () = Jv.call t "now" [||] |> Jv.to_float
  let of_ms ms = Jv.new' t [| Jv.of_float ms |]

  let pp_locale t =
    let format =
      Jv.obj
        [|
          ("year", Jv.of_string "numeric");
          ("month", Jv.of_string "short");
          ("day", Jv.of_string "numeric");
          ("weekday", Jv.of_string "short");
        |]
    in
    Jv.call t "toLocaleDateString" [| Jv.undefined; format |] |> Jv.to_jstr
end

module Element = struct
  type t = Brr.El.t

  let bind_on_click elem f =
    let target = Brr.El.as_target elem in
    Brr.Ev.listen Brr.Ev.click f target

  let set_attr elem attr value = Brr.El.set_at (Jstr.v attr) (Some value) elem

  let set_value elem v =
    let v = Jstr.v v in
    Brr.El.set_prop Brr.El.Prop.value v elem

  let value_string elem = Brr.El.prop Brr.El.Prop.value elem |> Jstr.to_string
  let value_int elem = Brr.El.prop Brr.El.Prop.value elem |> Jstr.to_int

  let set_innerHTML elem v =
    let innerHTML_prop = Brr.El.Prop.jstr (Jstr.v "innerHTML") in
    Brr.El.set_prop innerHTML_prop (Jstr.v v) elem
end

module Document = struct
  exception Not_found of string

  let lookup_by_id id : Element.t =
    let doc = Brr.G.document in
    match Brr.Document.find_el_by_id doc (Jstr.v id) with
    | None -> raise (Not_found (Fmt.str "Element with '%s' not found!" id))
    | Some el -> el

  let on_content_loaded f =
    let doc = Brr.G.document in
    let target = Brr.Document.as_target doc in
    let _ = Brr.Ev.listen Brr.Ev.dom_content_loaded f target in
    ()
end

module Window = struct
  let close () = Brr.(G.window |> Window.close)
end

module Tab = struct
  type t = Jv.t
  (** https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/tabs/Tab *)

  let title t = Jv.get t "title" |> Jv.to_string
  let url t = Jv.get t "url" |> Jv.to_string
end

module Storage = struct
  module Area = struct
    type t = Jv.t
    (** https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage/StorageArea *)

    let get t key =
      let ok v = Jv.get v key in
      Jv_lwt.of_promise ~ok @@ Jv.call t "get" [| Jv.of_string key |]

    let set t key value =
      let params = Jv.obj [| (key, value) |] in
      Jv_lwt.of_promise ~ok:Fun.id @@ Jv.call t "set" [| params |]
  end

  type t = Jv.t
  (** https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage *)

  let local t : Area.t = Jv.get t "local"
end

module Tabs = struct
  type t = Jv.t
  (** https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/tabs *)

  (** Returns the active tab in the current window. *)
  let active t : Tab.t Lwt.t =
    let query =
      Jv.obj
        [| ("active", Jv.of_bool true); ("currentWindow", Jv.of_bool true) |]
    in
    Jv_lwt.of_promise ~ok:(fun v -> Jv.to_list Fun.id v |> List.hd)
    @@ Jv.call t "query" [| query |]

  let create url t : t Lwt.t =
    let params = Jv.obj [| ("url", url) |] in
    Jv_lwt.of_promise ~ok:Fun.id @@ Jv.call t "create" [| params |]
end

module Runtime = struct
  type t = Jv.t
  (** https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/runtime *)

  (** Get url of a page within the extension *)
  let get_url path t = Jv.call t "getURL" [| Jv.of_string path |]
end

module Browser = struct
  let v : Jv.t = Jv.get Jv.global "browser"
  let runtime : Runtime.t = Jv.get v "runtime"
  let storage : Storage.t = Jv.get v "storage"
  let tabs : Tabs.t = Jv.get v "tabs"
end
