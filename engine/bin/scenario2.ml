open Bacterie_libs
open Local_libs
open Local_libs
open Numeric

let () = Printexc.record_backtrace true
let format_dummy : Handlers.log_formatter = fun item -> item.msg;;

let handler = Handlers.make (File ("stats", Debug)) in
let stats_reporter = Logging.get_logger "reacs_stats" in
stats_reporter#add_handler handler;
stats_reporter#set_level Debug;
Handlers.set_formatter handler format_dummy;
stats_reporter#info
  "ireactants areactants transitions grabs breaks  picked_dur treated_dur \
   actions_dur"

let env : Environment.t =
  {
    transition_rate = Q.of_string "10";
    grab_rate = Q.of_string "1";
    break_rate = Q.of_string "1/1000";
    collision_rate = Q.of_string "0";
  }

let bsig : Bacterie.bact_sig =
  {
    inert_mols =
      [
        { qtt = 1; mol = "A"; ambient = true };
        { qtt = 1; mol = "B"; ambient = true };
        { qtt = 1; mol = "C"; ambient = true };
        { qtt = 1; mol = "D"; ambient = true };
        { qtt = 1; mol = "F"; ambient = true };
        {
          mol = "DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA";
          qtt = 10;
          ambient = false;
        };
      ];
    active_mols =
      [
        {
          mol =
            "AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC";
          qtt = 10;
        };
      ];
  }

let bact = Bacterie.make ~bact_sig:bsig (ref env);;

for i = 0 to 1000000 do
  Bacterie.next_reaction bact
done
