open Bacterie_libs
open Local_libs


let () = Printexc.record_backtrace true;;
   
let format_dummy : Logger.Formatter.t = fun item -> item.msg;;
let handler = Logger.Handler.make_file_handler Logger.Debug "stats" in
    let stats_reporter = Logger.get_logger "reacs_stats" in
    stats_reporter#add_handler handler;
    stats_reporter#set_level (Some Debug);
    Logger.Handler.set_formatter handler format_dummy;
    stats_reporter#info "ireactants areactants transitions grabs breaks  picked_dur treated_dur actions_dur";;



let env : Environment.t = {
    transition_rate = 10.;
    grab_rate = 1.;
    break_rate = 0.001;
    random_collision_rate = 0.
  }


let bsig : Bacterie.bact_sig =
  {
    inert_mols= [
      {qtt=1;mol="A";ambient=true;};
      {qtt=1;mol="B";ambient=true;};
      {qtt=1;mol="C";ambient=true;};
      {qtt=1;mol="D";ambient=true;};
      {qtt=1;mol="F";ambient=true;};
      {mol="DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA";qtt=10; ambient=false}];
    active_mols= [{mol="AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC";qtt=10}]
  } 

let bact = Bacterie.make ~env:env ~bact_sig:bsig ();;
for i = 0 to 1000000 do
  Bacterie.next_reaction bact
done;;


