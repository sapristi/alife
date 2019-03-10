open Bacterie_libs
open Local_libs


let () = Printexc.record_backtrace true;;
   

let env : Environment.t = {
    transition_rate = 10.;
    grab_rate = 1.;
    break_rate = 0.001;
    random_collision_rate = 0.
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

let bact = Bacterie.make ~env:env ~bact_sig:bsig ();;

