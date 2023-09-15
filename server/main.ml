open Lwt.Syntax
module Store = Irmin_git_unix.FS.KV (Model)
module Codec = Irmin_server.Conn.Codec.Bin
module Server = Irmin_server_unix.Make_ext (Codec) (Store)

module Defaults = struct
  include Defaults

  let root =
    let home =
      match Sys.getenv_opt "HOME" with
      | Some home -> (* nixes *) home
      | None ->
          (* windows *)
          Option.value ~default:"" @@ Sys.getenv_opt "USERPROFILE"
    in
    Filename.concat home ".irmin-bookmarks"
end

let main port root =
  let uri = Uri.of_string (Fmt.str "ws://localhost:%d/ws" port) in
  let config = Irmin_git.config root in
  let* server = Server.v ~uri config in
  Logs.info (fun l -> l "Storing data at %s" root);
  Logs.info (fun l -> l "Listening on port %d" port);
  Server.serve server

let run port root =
  Fmt_tty.setup_std_outputs ();
  Logs.(set_level @@ Some Info);
  Irmin.Export_for_backends.Logging.reporter (module Mtime_clock)
  |> Logs.set_reporter;
  Lwt_main.run @@ main port root

(* CLI *)

open Cmdliner

let cmd =
  let info = Cmd.info "irmin-bookmarks" ~doc:"server for irmin-bookmarks" in
  let port =
    let doc = "bind server to this port" in
    Arg.(value & opt int Defaults.port & info [ "p"; "port" ] ~docv:"PORT" ~doc)
  in
  let root =
    let doc = "store data at this path" in
    Arg.(
      value & opt string Defaults.root & info [ "r"; "root" ] ~docv:"ROOT" ~doc)
  in
  Cmd.v info Term.(const run $ port $ root)

let () = exit (Cmd.eval cmd)
