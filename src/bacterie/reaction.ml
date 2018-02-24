open Reactions
  
module MakeReaction (Reactants: REACTANTS) =
  struct
    include ReactionsM(Reactants)

    
(* * General reaction module *)
   module rec Reaction :
         (sig
           type t =
             | Grab of Grab.t ref
             | Transition of Transition.t ref
             | Break of Break.t ref
                      (*
           type reaction_effect =
             | R_effects of Reactants.effect list
             | Update_reacs of Reactants.t
             | Remove_one of Reactants.t
             | Release_mol of Molecule.t
                       *)          
           val treat_reaction : t -> effect list
           val compare : t -> t -> int
           val show : t -> bytes
                             (*           val unlink : t -> unit *)
         end)
     =
     struct
(* ** module definition *)

       type t =
         | Grab of Grab.t ref
         | Transition of Transition.t ref
         | Break of Break.t ref
                                      [@@ deriving ord, show]    
                         
     (*  type reaction_effect =
         | R_effects of Reactants.effect list
         | Update_reacs of Reactants.t
         | Remove_one of Reactants.t
         | Release_mol of Molecule.t*)
         
       let rate r =
         match r with
         | Transition t -> Transition.rate (!t)
         | Grab g -> Grab.rate (!g)
         | Break ba -> Break.rate !ba
                     
       let treat_reaction r  : effect list=
         match r with
         | Transition t -> Transition.eval !t
         | Grab g -> Grab.eval !g
         | Break ba -> Break.eval !ba
                    (* 
       let unlink r =
         let linked_reacSets = 
           match r with
           | Transition t -> Transition.linked_reacSets !t
           | Grab g -> Grab.linked_reacSets !g
           | BreakA ba -> Break.linked_reacSets !ba
         in
         List.iter (fun s -> s := ReacSet.remove r !s) linked_reacSets
                     *)
     end
     
     
(* * ReacSet module *)
   and ReacSet :
         (sig
           include Set.S with type elt =  Reaction.t
           val show : t -> string
         end)
     =
     struct
       
       include Set.Make (Reaction)
           
       let show (rset :t) =
         fold (fun (reac : Reaction.t) desc ->
             (Reaction.show reac)^"\n"^desc)
              rset
              ""
       let pp (f : Format.formatter) (rset : t) =
         Format.pp_print_string f "reactions set"
     end

  end
