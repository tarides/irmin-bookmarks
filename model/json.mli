type t [@@deriving irmin]

val empty : unit -> t
val set_string : string -> string -> t -> t
val set_float : string -> float -> t -> t
val get_string : t -> string -> string
val get_float : t -> string -> float
