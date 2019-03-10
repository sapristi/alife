open Bacterie_libs
open Local_libs


   
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
    break_rate = 0.00001;
    random_collision_rate = 0.
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
    let bact = Bacterie.make ~env:env ~bact_sig:s () in
    
    for i = 0 to 200 do
      Bacterie.next_reaction bact;
    done) sigs
