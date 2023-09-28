type t
type connect_result = (t, string) result

val connect : unit -> connect_result Lwt.t
(** Attempt to connect to the local server *)

val list : t -> Model.t list Lwt.t
(** List all bookmarks, unsorted *)

val load : t -> Model.t -> Model.t option Lwt.t
(** Load a model from the local repository *)

val save : t -> Model.t -> (unit, string) result Lwt.t
(** Save a model to the local repository *)

val delete : t -> Model.t -> (unit, string) result Lwt.t
(** Delete a model from the local repository *)
