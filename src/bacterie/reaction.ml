open Reactions

   
module rec
    Reactant :
      (sig 
        include REACTANT with type reac = Reaction.t
                          and type reacSet = ReacSet.t 
      end)
  =
  struct
    type reac = Reaction.t
    type reacSet = ReacSet.t
                 
    module type REACTANT_DEFAULT =
      (Reactant.REACTANT_DEFAULT)
      
(* *** inert mol data *)
    module ImolSet =
      struct
        type t = {
            mol : Molecule.t;
            qtt : int; 
            reacs : ReacSet.t ref; 
          }
        let show (imd : t) =
          let res = Printf.sprintf "Inert : %s (%i)" imd.mol imd.qtt
          in Bytes.of_string res
           
        let pp (f : Format.formatter) (imd : t) =
          Format.pp_print_string f (show imd)
               
        let mol ims = ims.mol
        let qtt ims = ims.qtt
        let reacSet ims = !(ims.reacs)
        let add_to_qtt deltaqtt ims =
          {ims with qtt = ims.qtt + deltaqtt}
        let set_qtt qtt ims =
          {ims with qtt = qtt}
        let make_new mol : t = {mol; qtt=0; reacs = (ref ReacSet.empty)}
        let add_reac (reac : Reaction.t) (imd : t) =
          imd.reacs := ReacSet.add reac !(imd.reacs)
        let remove_reac (reac : Reaction.t) (imd : t) =
          imd.reacs := ReacSet.remove reac !(imd.reacs)
          
        let compare (imd1 : t) (imd2 : t) =
          String.compare imd1.mol imd2.mol

      end
      
(* *** active mol data *)
    module Amol = 
      struct
        type t = {
            mol : Molecule.t;
            pnet : Petri_net.t;
            reacs : ReacSet.t ref; 
          }
        let show am = 
          let res = Printf.sprintf "Active mol : %s (id : %d)" am.mol am.pnet.uid 
          in Bytes.of_string res
        let pp f am =
          Format.pp_print_string f (show am)
          
        let mol am =  am.mol
        let qtt am = 1
        let reacSet am = !(am.reacs)
        let pnet am = am.pnet
        let make_new (pnet : Petri_net.t) =
          {mol = pnet.mol; pnet; reacs = ref ReacSet.empty}
          
        let add_reac reac (amd : t) =
          amd.reacs := ReacSet.add reac !(amd.reacs) 
          
        let remove_reac (reac : Reaction.t) (amd : t) =
          amd.reacs := ReacSet.remove reac !(amd.reacs)
        let compare
              (amd1 : t) (amd2 : t) =
          Pervasives.compare amd1.pnet.Petri_net.uid amd2.pnet.Petri_net.uid
                
      end
(* *** active mol set *)
    (*
  module ASet = Batteries.Set.Make(struct type t = Active.t ref
                                          let compare a1 a2 =
                                            Active.compare !a1 !a2 end)
  module ActiveSet =
    struct
      type t = {  mol : Molecule.t;
                  qtt : int;
                  reacs : ReacSet.t ref;
                  pnets : ASet.t; }
             
      let make mol (pnets : ASet.t) reacs : t =
        {mol; pnets; reacs; qtt = ASet.cardinal pnets}
        
      let make_new mol =
        {mol = mol; pnets=ASet.empty; qtt = 0;
         reacs = ref ReacSet.empty}
        
      let add_reac reac (amsd : t) =
        amsd.reacs := ReacSet.add reac !(amsd.reacs) 
        
      let compare
            (amsd1 : t) (amsd2 : t) =
        Pervasives.compare amsd1.mol amsd2.mol
        
      let show (amd : t) =
        let res = Printf.sprintf "Active Set : %s" amd.mol
        in Bytes.of_string res
         
      let pp (f : Format.formatter)
             (amd : t)
        = Format.pp_print_string f (show amd)
    end
 *)
(* *** General *)   
    type t =
      | Amol of Amol.t ref
      | ImolSet of ImolSet.t ref
                             [@@ deriving show, ord]
    let qtt reactant =
      match reactant with
      | Amol amol -> Amol.qtt !amol
      | ImolSet ims -> ImolSet.qtt !ims
    let mol reactant =
      match reactant with
      | Amol amol -> Amol.mol !amol
      | ImolSet ims -> ImolSet.mol !ims
    let reacSet reactant =
      match reactant with
      | Amol amol -> Amol.reacSet !amol
      | ImolSet ims -> ImolSet.reacSet !ims
    let add_reac reaction reactant =
      match reactant with 
      | Amol amol -> Amol.add_reac reaction !amol
      | ImolSet ims -> ImolSet.add_reac reaction !ims
    let remove_reac reaction reactant =
      match reactant with 
      | Amol amol -> Amol.remove_reac reaction !amol
      | ImolSet ims -> ImolSet.remove_reac reaction !ims
  end
  
   and Reacs :
         (sig
           
           type effect =
             | T_effects of Place.transition_effect list
             (* handles the side effects of removing
                an element, e.g. removing a pnet
                will release the tokens
                (this means the tokens won't interact
                with the grabing molecule ? *)
             | Remove_one of Reactant.t
             | Update_reacs of Reactant.reacSet
             | Release_mol of Molecule.t
             | Release_tokens of Token.t list
           module type REAC =
             sig
               type t
               type build_t
               val show : t -> string
               val pp : Format.formatter -> t -> unit
               val compare : t -> t -> int
               val rate : t -> float
               val update_rate : t -> float
               val make : build_t -> t
               val eval : t -> effect list
               val remove_reac_from_reactants : Reaction.t -> t -> unit
           
             end
              
           module Grab :
           (REAC with type build_t = (Reactant.Amol.t ref *
                                        Reactant.t ))
                
           module Transition  :
           (REAC with type build_t = Reactant.Amol.t ref)
                
             
           module Break :
           (REAC with type build_t = (Reactant.t))
         end)
     = struct
     include ReactionsM(Reactant) 
   end
     
(* * General reaction module *)
   and Reaction :
         (sig
        type t  =
          | Grab of Reacs.Grab.t ref
          | Transition of Reacs.Transition.t ref
          | Break of Reacs.Break.t ref
                   
        val treat_reaction : t -> Reacs.effect list
        val compare : t -> t -> int
        val show : t -> bytes
        val unlink : t -> unit
      end)
  =
  struct
(* ** module definition *)
    open Reacs
    type t =
      | Grab of Grab.t ref
      | Transition of Transition.t ref
      | Break of Break.t ref
                         [@@ deriving ord, show]    
               
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
                  
    let unlink r = 
      match r with
      | Transition t -> Transition.remove_reac_from_reactants r !t
      | Grab g -> Grab.remove_reac_from_reactants r !g
      | Break ba -> Break.remove_reac_from_reactants r !ba
                     
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

