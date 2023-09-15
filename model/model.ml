type t = { name : string; notes : string; url : string; created_at : float }
[@@deriving irmin]

let v ~created_at ~name ~url ~notes = { name; notes; url; created_at }

let key_path t =
  let module Hash = Irmin.Hash.SHA256 in
  let uri = Uri.of_string t.url in
  let hash = Hash.hash (fun f -> f t.url) in
  let id = Fmt.str "%a" Irmin.Type.(pp Hash.t) hash in
  let host = match Uri.host uri with None -> "unknown" | Some h -> h in
  [ host; id ]

let equal a b = List.equal String.equal (key_path a) (key_path b)

let of_json obj =
  let created_at = Json.get_float obj "created_at" in
  let name = Json.get_string obj "name" in
  let notes = Json.get_string obj "notes" in
  let url = Json.get_string obj "url" in
  { name; url; notes; created_at }

let to_json t =
  Json.empty ()
  |> Json.set_string "url" t.url
  |> Json.set_string "notes" t.notes
  |> Json.set_string "name" t.name
  |> Json.set_float "created_at" t.created_at

let t = Irmin.Type.map Json.t of_json to_json
let merge = Irmin.Merge.(option (default t))
