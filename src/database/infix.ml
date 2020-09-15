open Lwt.Infix

let (>>=?) m f =
  m >>= (function | Ok x -> f x | Error err -> Lwt.return (Error err))

let (>|=?) m f =
  m >|= (function | Ok x -> f x | Error err -> Error err)

let (>>==) m f =
  m >>= (function | Ok x -> f x | Error err -> Lwt.return ())
