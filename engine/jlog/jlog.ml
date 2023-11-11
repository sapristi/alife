module Types = Internals.Types
module Formatters =  Formatters

open Types

type level = Types.level = | Debug | Info | Warning | Error | NoLevel
let string_of_level = Types.string_of_level

let log_infra : Internals.Types.log_infra = {
  handlers = []
}

let register_handler name handler =
  let name_l = Internals.Utils.Name.to_l name in
  log_infra.handlers <- (name_l, handler)::log_infra.handlers

let make_logger name =
  let name_l = Internals.Utils.Name.to_l name in
  let _log_custom = Internals._log log_infra name_l name
  in {
        debug=_log_custom Debug;
        info=_log_custom  Info;
        warning=_log_custom Warning;
        error=_log_custom Error;
      }


let make_handler ?(formatter=Formatters.default) ?(output=print_endline) ?(level=Debug) ?(propagate=false) () =
  {
    formatter; output; level; propagate
  }


