

open Reactions

   
(* * The MolData module *)
(* ** module signature *)
module rec MolData :
             (Reactions.MOLDATA with
                type reacSet = ReacSet.t and
                type reac = Reaction.t)
         
(* ** module definition *)
  = struct
  
(* *** inert mol data *)
  module Inert =
    struct
      type t = {
          mol : Molecule.t;
          qtt : int ref; 
          reacs : ReacSet.t ref; 
        }
             
      let make mol qtt reacs : t = {mol;qtt;reacs}
      let make_new mol qtt : t = {mol; qtt; reacs = ref (ReacSet.empty)}
      let add_reac (reac : Reaction.t) (imd : t) =
        imd.reacs := ReacSet.add reac !(imd.reacs) 
      let compare (imd1 : t) (imd2 : t) =
        String.compare imd1.mol imd2.mol
      let show (imd : t) =
        let res = Printf.sprintf "Inert : %s (%i)" imd.mol !(imd.qtt)
        in Bytes.of_string res
         
      let pp (f : Format.formatter)
             (imd : t)
        = Format.pp_print_string f (show imd)
    end
    
(* *** active mol data *)
  module Active = 
    struct
      type t = {
          mol : Molecule.t;
          pnet : Petri_net.t ref;
          reacs : ReacSet.t ref; 
        }
             
      let make (pnet : Petri_net.t ref) reacs :
            t =
        {mol = !pnet.mol; pnet; reacs}
        
      let make_new (pnet : Petri_net.t ref) =
        {mol = !pnet.mol; pnet; reacs = ref ReacSet.empty}
        
      let add_reac reac (amd : t) =
        amd.reacs := ReacSet.add reac !(amd.reacs) 
        
      let compare
            (amd1 : t) (amd2 : t) =
        Pervasives.compare !(amd1.pnet).Petri_net.uid !(amd2.pnet).Petri_net.uid
        
      let show (amd : t) =
        let res = Printf.sprintf "Active : %s" amd.mol
        in Bytes.of_string res
         
      let pp (f : Format.formatter)
             (amd : t)
        = Format.pp_print_string f (show amd)
    end
(* *** reaction effect and others *)               
  type reaction_effect =
    | T_effects of Place.transition_effect list
    | Remove_pnet of Active.t
    | Update_reacs of ReacSet.t 
    | Modify_quantity of Inert.t * int
                                  
  type reac = Reaction.t      
  type reacSet = ReacSet.t
  let union rs1 rs2 =  ReacSet.union rs1 rs2
end
         
(* * Specific reaction modules *)
   and Grab :
         (Reactions.REAC
          with type reacSet = MolData.reacSet
           and type build_t = (MolData.Active.t * MolData.Inert.t)
           and type effect = MolData.reaction_effect) 
     = GrabM(MolData) 
   and AGrab :
         (Reactions.REAC 
          with type reacSet = MolData.reacSet
           and type build_t = (MolData.Active.t * MolData.Active.t)
           and type effect = MolData.reaction_effect)  
     = AGrabM(MolData)
   and Transition :
         (Reactions.REAC
          with type reacSet = MolData.reacSet
           and type build_t = MolData.Active.t
           and type effect = MolData.reaction_effect)
     = TransitionM(MolData)
     
(* * General reaction module *)
   and Reaction :
         (sig
           type t = 
             | Grab of Grab.t ref
             | AGrab of AGrab.t ref
             | Transition of Transition.t ref
                           
           val treat_reaction : t -> MolData.reaction_effect list
           val compare : t -> t -> int
           val show : t -> bytes
           val unlink : t -> unit
         end)
     =
     struct
(* ** module definition *)

       type t =
         | Grab of Grab.t ref
         | AGrab of AGrab.t ref
         | Transition of Transition.t ref
                                      [@@ deriving show, ord]
       let rate r  =
         match r with
         | Transition t -> Transition.rate (!t)
         | Grab g -> Grab.rate (!g)
         | AGrab ag -> AGrab.rate (!ag)
                     
       let treat_reaction r =
         match r with
         | Transition t -> Transition.eval !t
         | Grab g -> Grab.eval !g
         | AGrab ag -> AGrab.eval !ag
                     
       let unlink r =
         let linked_reacSets = 
           match r with
           | Transition t -> Transition.linked_reacSets !t
           | Grab g -> Grab.linked_reacSets !g
           | AGrab ag -> AGrab.linked_reacSets !ag
         in
         List.iter (fun s -> s := ReacSet.remove r !s) linked_reacSets
     end
     
     
(* * ReacSet module *)
   and ReacSet :
         (sig
           include Set.S with type elt = Reaction.t
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

