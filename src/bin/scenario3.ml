open Bacterie_libs
open Local_libs
open Numeric.Num


let () = Printexc.record_backtrace true;;
   

let env : Environment.t = {
    transition_rate = (num_of_string "1");
    grab_rate = num_of_string "1";
    break_rate = num_of_string "1/1000";
    random_collision_rate = zero
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

let bact = Bacterie.make ~bact_sig:bsig env;;

