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
