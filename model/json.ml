type t = Irmin.Contents.Json.t [@@deriving irmin]

let empty () = []
let set_string k v t = (k, `String v) :: t
let set_float k v t = (k, `Float v) :: t
let force_string = function `String s -> s | _ -> assert false
let force_float = function `Float n -> n | _ -> assert false
let get_string obj key = List.assoc key obj |> force_string
let get_float obj key = List.assoc key obj |> force_float
