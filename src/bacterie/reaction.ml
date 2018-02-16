

open Reactions

   
(* * The MolData module *)
(* ** module signature *)
module rec MolData : sig
         type reacsSet = ReacsSet.t
                       
         type inert_md = {
             mol : Molecule.t;
             qtt : int ref; 
             reacs : ReacsSet.t ref; 
           }

         val show_inert_md : inert_md -> string
         val pp_inert_md : Format.formatter -> inert_md -> unit
         val compare_inert_md : inert_md -> inert_md -> int
           
         type active_md= {
                 mol : Molecule.t;
                 pnet : Petri_net.t ref;
                 reacs : ReacsSet.t ref; 
               }
            
         val show_active_md : active_md -> string
         val pp_active_md : Format.formatter -> active_md -> unit
         val compare_active_md : active_md -> active_md -> int
           
         val union : reacsSet -> reacsSet -> reacsSet
           
         type reaction_effect =
           | T_effects of Place.transition_effect list
           | Remove_pnet of active_md
           | Update_reacs of reacsSet
           | Modify_quantity of inert_md * int
       end
(* ** module definition *)
                     = struct
             
(* *** inert mol data *)
                                  
             type inert_md = {
                 mol : Molecule.t;
                 qtt : int ref; 
                 reacs : ReacsSet.t ref; 
               }
                           
             let make_inert_md mol qtt reacs : inert_md = {mol;qtt;reacs}
             let make_new_inert_md mol qtt : inert_md = {mol; qtt; reacs = ref (ReacsSet.empty)}
             let add_reac_to_inert_md (reac : Reaction.t) (imd : inert_md) =
               imd.reacs := ReacsSet.add reac !(imd.reacs) 
             let compare_inert_md
                   (imd1 : inert_md) (imd2 : inert_md) =
               String.compare imd1.mol imd2.mol
             let show_inert_md (imd : inert_md) =
               let res = Printf.sprintf "Inert : %s (%i)" imd.mol !(imd.qtt)
               in Bytes.of_string res
                
             let pp_inert_md (f : Format.formatter)
                             (imd : inert_md)
               = Format.pp_print_string f (show_inert_md imd)
    
               
(* *** active mol data *)
    
             type active_md = {
                 mol : Molecule.t;
                 pnet : Petri_net.t ref;
                 reacs : ReacsSet.t ref; 
               }
                            
             let make_active_md (pnet : Petri_net.t ref) reacs :
                   active_md =
               {mol = !pnet.mol; pnet; reacs}
               
             let make_new_active_md (pnet : Petri_net.t ref) =
               {mol = !pnet.mol; pnet; reacs = ref ReacsSet.empty}
               
             let add_reac_to_active_md reac (amd : active_md) =
               amd.reacs := ReacsSet.add reac !(amd.reacs) 
               
             let compare_active_md 
                   (amd1 : active_md) (amd2 : active_md) =
               Pervasives.compare !(amd1.pnet).Petri_net.uid !(amd2.pnet).Petri_net.uid
               
             let show_active_md (amd : active_md) =
               let res = Printf.sprintf "Active : %s" amd.mol
               in Bytes.of_string res
                
             let pp_active_md (f : Format.formatter)
                              (amd : active_md)
               = Format.pp_print_string f (show_active_md amd)
               
(* *** reaction effect and others *)               
             type reaction_effect =
               | T_effects of Place.transition_effect list
               | Remove_pnet of active_md
               | Update_reacs of ReacsSet.t 
               | Modify_quantity of inert_md * int
                                  
                                  
             type reacsSet = ReacsSet.t
             let union rs1 rs2 =  ReacsSet.union rs1 rs2
           end
         
(* * Specific reaction modules *)
   and Grab : Reactions.REAC
     = GrabM(MolData)      
   and AGrab : Reactions.REAC
     = AGrabM(MolData)
   and Transition : Reactions.REAC
     = TransitionM(MolData)


(* * General reaction module *)
   and Reaction : sig
     
     type t = 
       | Grab of Grab.t ref
       | AGrab of AGrab.t ref
       | Transition of Transition.t ref
                     
     val compare : t -> t -> int
     val show : t -> bytes  
           
       end
  = struct
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
end


(* * ReacsSet module *)
   and ReacsSet :
         sig
           include Set.S with type elt := Reaction.t
           val show : t -> string
         end
         = struct
         
     include Set.Make (Reaction)
               
         let show (rset :t) =
           fold (fun (reac : Reaction.t) desc ->
               (Reaction.show reac)^"\n"^desc)
                rset
                ""
         let pp (f : Format.formatter) (rset : t) =
           Format.pp_print_string f "reactions set"

   end


         
(* * Set modules for reactions *)


let grab_reac = (module Grab : Reactions.REAC)
let agrab_reac = (module AGrab : Reactions.REAC)
let transition_reac = (module Transition : Reactions.REAC)
                    
let reacs_modules = [grab_reac; agrab_reac; transition_reac]

module SetWithShow (E : sig
                      type t
                      val show : t -> string
                      val compare : t -> t -> int
                    end)
  = struct
  include Set.Make(E)
  let show (s : t) =
    fold (fun (e : elt) desc ->
        (E.show e)^"\n"^desc) s ""
    end

module type SETWITHSHOW =
  sig
    include Set.S
    val show : t -> string
  end

let test (r : (module REAC)) =
  let module R = (val r) in
  let module RS = SetWithShow(R) in
  (module RS :  SETWITHSHOW)
  
let reacs_set = List.map
                  test
                  reacs_modules
         
module GrabsSet =
  struct 
    include Set.Make (Grab)
          
    let show (gs :t) =
           fold (fun (g : elt) desc ->
               (Grab.show g)^"\n"^desc)
                gs
                ""
  end
                          
module AGrabsSet =
  struct
    include Set.Make (AGrab)
          
    let show (ags :t) =
      fold (fun (ag : elt) desc ->
          (AGrab.show ag)^"\n"^desc)
           ags
           ""
      
  end
                          
module TransitionsSet =
  struct
  include 
    Set.Make (Transition)
  let show (ts : t) =
      fold (fun (t : elt) desc ->
          (Transition.show t)^"\n"^desc)
           ts
           ""


  end


