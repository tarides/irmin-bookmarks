module Store = struct
  module Git_impl = Irmin_git.Mem
  module Sync = Git.Mem.Sync (Git_impl)
  module Maker = Irmin_git.KV (Git_impl) (Sync)
  include Maker.Make (Model)
end

module Codec = Irmin_server.Conn.Codec.Bin
include Irmin_client_jsoo.Make_codec (Codec) (Store)
open Lwt.Syntax
module Info_jsoo = Irmin_client_jsoo.Info (Info)

let author = "irmin-bookmarks"

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

(* Utility function to return exceptions as errors so that UI can show them *)
let catch f =
  Lwt.catch
    (fun () ->
      let+ _ = f () in
      Ok ())
    (fun exn -> Lwt.return_error (Printexc.to_string exn))

let update t f ~info =
  catch @@ fun () ->
  let repo = repo t in
  (* Get latest tree for main branch *)
  let* main = of_branch repo Store.Branch.main in
  let* head = Head.get main in
  (* Apply [f] to the tree on main to get our new tree *)
  let* tree = Commit.tree head |> f in
  (* Commit this tree *)
  let* commit = Commit.v repo ~info ~parents:[ Commit.key head ] tree in
  (* Merge commit to main *)
  let* main = of_branch repo Branch.main in
  merge_with_commit main commit ~info:(Info_jsoo.v ~author "Merge to main")

let list t =
  let* tree = tree t in
  Tree.fold ~order:`Undefined
    ~contents:(fun _path m acc -> m :: acc |> Lwt.return)
    tree []

let load t model =
  let key = Model.key_path model in
  find t key

let save t model =
  let f tree =
    let key = Model.key_path model in
    Tree.add tree key model
  in
  update t f ~info:(Info_jsoo.v ~author "Update %s" model.url ())

let delete t model =
  let f tree =
    let key = Model.key_path model in
    Tree.remove tree key
  in
  update t f ~info:(Info_jsoo.v ~author "Delete %s" model.url ())
