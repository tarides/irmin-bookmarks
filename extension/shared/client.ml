module Store = struct
  module Git_impl = Irmin_git.Mem
  module Sync = Git.Mem.Sync (Git_impl)
  module Maker = Irmin_git.KV (Git_impl) (Sync)
  include Maker.Make (Model)
end

module Codec = Irmin_server.Conn.Codec.Bin
include Irmin_client_jsoo.Make_codec (Codec) (Store)
open Lwt.Syntax

let info =
  let module Info = Irmin_client_jsoo.Info (Info) in
  Info.v ~author:"irmin-bookmarks"

type connect_result = (t, string) result

let connect () =
  let* prefs = Preferences.load () in
  let uri = Uri.of_string (Fmt.str "ws://localhost:%d/ws" prefs.port) in
  Lwt.catch
    (fun () ->
      let* client = connect uri in
      let+ main = main client in
      Ok main)
    (fun _exn ->
      Lwt.return
        (Error (Fmt.str "Could not connect to server on port %d" prefs.port)))

let list t =
  let* tree = tree t in
  Tree.fold ~order:`Undefined
    ~contents:(fun _path m acc -> m :: acc |> Lwt.return)
    tree []

let load t model =
  let key = Model.key_path model in
  find t key

let catch f =
  Lwt.catch
    (fun () ->
      let+ _ = f () in
      Ok ())
    (fun exn -> Lwt.return_error (Printexc.to_string exn))

let save t model =
  let key = Model.key_path model in
  catch @@ fun () -> set_exn ~info:(info "Update %s" model.url) t key model

let delete t model =
  let key = Model.key_path model in
  catch @@ fun () -> remove_exn ~info:(info "Delete %s" model.url) t key
