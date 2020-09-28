open Lwt.Infix

let (>>=?) m f =
  m >>= (function | Ok x -> f x | Error err -> Lwt.return (Error err))

let (>|=?) m f =
  m >|= (function | Ok x -> f x | Error err -> Error err)

let (>>==) m f =
  m >>= (function | Ok x -> f x | Error err -> Lwt.return ())

let (>>=!) m f =
  m >>= (function | Ok x -> f x | Error err -> raise (Caqti_error.Exn err))

let (>|=!) m f =
  m >|= (function | Ok x -> f x | Error err -> raise (Caqti_error.Exn err))

let (>>=.) m f =
  m >>= (function | Ok x -> f x | Error err -> Error (Caqti_error.show err) |> Lwt.return)

let (>|=.) m f =
  m >|= (function | Ok x -> f x | Error err -> Error (Caqti_error.show err))

let to_string_res = function
  | Ok x -> Ok x | Error err -> Error (Caqti_error.show err)
