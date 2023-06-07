open Bacterie_libs
open Local_libs
open Numeric


let () = Printexc.record_backtrace true;;
   

let env : Environment.t = {
    transition_rate = (Q.of_string "1");
    grab_rate = Q.of_string "1";
    break_rate = Q.of_string "1/1000";
    collision_rate = Q.zero
  }


let bsig : Bacterie.bact_sig =
  {
    inert_mols= [
      (*{qtt=1;mol="A";ambient=true;};
      {qtt=1;mol="B";ambient=true;};
      {qtt=1;mol="C";ambient=true;};
      {qtt=1;mol="D";ambient=true;};
      {qtt=1;mol="F";ambient=true;};*)
      {mol="DDBBAFDDAABCAAAFDDFBFABAFDDAAABAAAFDDAAABFDDFAFABAAAAA";qtt=10; ambient=false}];
    active_mols= [(*{mol="AAABAAAADDFCBAAADDFBAAABDDFCBAABDDFBAAACDDFCBAACDDFBAAADDDFCBAADDDFBAAAFDDFCBAAFDDFBAAAAADDFCAABBBDDFAAABAAAADDFABAFAFDDFAAABAAABDDFABAFBFDDFAAABAAACDDFABAFCFDDFAAABAAADDDFABAFDFDDFAAABAAAFDDFABAFFFDDFAAABCAAADDFCCAAADDFBCBABDDFCCAABDDFBCCACDDFCCAACDDFBCDADDDFCCAADDDFBCFAFDDFCCAAFDDFBABAAADDFCAABBBDDFAAACAAAAADDFABBAAACAAAAADDFABBAAABAABBBDDFCAACCCDDFAAABAABBBDDFABADFDFFFDDFAAABBACCCDDFCAACCCDDFABC";qtt=10}*)]
  } 

let bact = Bacterie.make ~bact_sig:bsig (ref env);;

