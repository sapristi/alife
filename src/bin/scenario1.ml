open Bacterie_libs
open Local_libs


   
open Easy_logging_yojson
open Numeric.Num
let () = Printexc.record_backtrace true;;
   
let format_dummy : Default_handlers.log_formatter = fun item -> item.msg;;
let handler = Default_handlers.make (File ("stats", Debug)) in
    let stats_reporter = Logging.get_logger "reacs_stats" in
    stats_reporter#add_handler handler;
    stats_reporter#set_level (Debug);
    Default_handlers.set_formatter handler format_dummy;
    stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";;


let env : Environment.t = {
    transition_rate = (num_of_string "10");
    grab_rate = num_of_string "1";
    break_rate = num_of_string "1/100000";
    collision_rate = num_of_string "0"
  }


let nbs = [1;10;20;40;60;100;140;200]
let sigs =
  List.map
    (fun x ->
      ({
          inert_mols= [
            {qtt=1;mol="A";ambient=true;};
            {qtt=1;mol="B";ambient=true;};
            {qtt=1;mol="C";ambient=true;};
            {qtt=1;mol="D";ambient=true;};
            {qtt=1;mol="F";ambient=true;};
            {mol="DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA";qtt=x; ambient=false}];
          active_mols= [{mol="AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC";qtt=x}]
        } : Bacterie.bact_sig) ) nbs;;
    
List.iter
  (fun s ->
    let bact = Bacterie.make  ~bact_sig:s (ref env) in
    
    for i = 0 to 200 do
      Bacterie.next_reaction bact;
    done) sigs
