
open Misc_library


module rec Reaction : sig
         type active_md = { mol : Molecule.t;
                            pnet : Petri_net.t ref;
                            reacs : ReacsSet.t ref; }
         val show_active_md : active_md -> string
                        
         type inert_md = {   mol : Molecule.t;
                             qtt : int ref; 
                             reacs : ReacsSet.t ref; }
         val show_inert_md : inert_md -> string
           
         type grab = { mutable rate : float;
                       graber_data : active_md;
                       grabed_data : inert_md;}
         val make_grab : active_md -> inert_md -> grab
         val show_grab : grab -> bytes
         val grab_rate : active_md -> inert_md -> float
         val grab_rate_aux : grab -> float
         val compare_grab : grab -> grab -> int
           
         type agrab = { mutable rate : float;
                       graber_data : active_md;
                       grabed_data : active_md;}
         val show_agrab : agrab -> bytes
         val make_agrab : active_md -> active_md -> agrab
         val agrab_rate : active_md -> active_md -> float
         val agrab_rate_aux : agrab -> float
         val compare_agrab : agrab -> agrab -> int
           
         type transition= { mutable rate : float;
                            amd : active_md;}
         val show_transition : transition -> bytes
         val make_transition : active_md -> transition
         val transition_rate : active_md -> float
         val transition_rate_aux : transition -> float
         val compare_transition : transition -> transition -> int
           
         type t = 
           | Transition of transition ref
           | Grab of grab ref
           | AGrab of agrab ref

         type reaction_effect =
           | T_effects of Place.transition_effect list
           | Remove_pnet of Molecule.t * Petri_net.t ref
           | Update of ReacsSet.t ref
         val treat_reaction : t -> reaction_effect list
         val rate : t -> float
         val compare : t -> t -> int
         val show : t -> bytes
         val unlink : t -> unit
       end
  = struct
  
  type reaction_effect =
    | T_effects of Place.transition_effect list
    | Remove_pnet of Molecule.t * Petri_net.t ref
    | Update of ReacsSet.t ref
  
  type inert_md = {
      mol : Molecule.t;
      qtt : int ref; 
      reacs : ReacsSet.t ref; 
    }
   and active_md = {
       mol : Molecule.t;
       pnet : Petri_net.t ref;
       reacs : ReacsSet.t ref; 
     }

(* ** mol data *)
                       
  let compare_inert_md
        (imd1 : inert_md) (imd2 : inert_md) =
    String.compare imd1.mol imd2.mol
  let compare_active_md 
        (amd1 : active_md) (amd2 : active_md) =
    Pervasives.compare !(amd1.pnet).Petri_net.uid !(amd2.pnet).Petri_net.uid
    
  let show_inert_md (imd : inert_md) =
    let res = Printf.sprintf "Inert : %s (%i)" imd.mol !(imd.qtt)
    in Bytes.of_string res
     
  let pp_inert_md (f : Format.formatter)
                        (imd : inert_md)
    = Format.pp_print_string f (show_inert_md imd)
    

  let show_active_md (amd : active_md) =
    let res = Printf.sprintf "Active : %s" amd.mol
    in Bytes.of_string res

  let pp_active_md (f : Format.formatter)
                        (amd : active_md)
    = Format.pp_print_string f (show_active_md amd)
    
(* ** grab *)
     
  type grab = {
      mutable rate : float;
      graber_data : active_md;
      grabed_data : inert_md;
    }
                [@@ deriving ord, show]

  let grab_rate (amd : active_md) (imd : inert_md) =
    float_of_int (Petri_net.grab_factor imd.mol !(amd.pnet)) *.
      float_of_int !(imd.qtt) 
  let grab_rate_aux (g : grab) =
    float_of_int (Petri_net.grab_factor
                    g.grabed_data.mol
                    !(g.graber_data.pnet)) *.
      float_of_int !(g.grabed_data.qtt) 

  let make_grab amd imd : grab =
    {
      rate = grab_rate amd imd;
      graber_data = amd;
      grabed_data = imd;}
    
(* ** agrab *)
  type agrab = {
      mutable rate : float;
      graber_data : active_md;
      grabed_data : active_md;
    }  
                 [@@ deriving ord, show]
             
  let agrab_rate (graber_d : active_md) (grabed_d : active_md) =
    1.
  let agrab_rate_aux (ag : agrab) = 1.
                                  
  let make_agrab graber_data grabed_data : agrab =
    {
      rate = agrab_rate graber_data grabed_data;
      graber_data;
      grabed_data;}
    
(* ** transition *)
  type transition = {
      mutable rate : float;
      amd : active_md;
    }
                      [@@ deriving ord, show]
                 
  let transition_rate (amd : active_md)  =
    (float_of_int !(amd.pnet).launchables_nb)
    
  let transition_rate_aux (t : transition)  =
    (float_of_int !(t.amd.pnet).launchables_nb)
  let make_transition amd : transition =
    {
      rate = transition_rate amd;
      amd;
    }
    
  type t =
    | Transition of transition ref
    | Grab of grab ref
    | AGrab of agrab ref
[@@ deriving ord, show]

  let rate r  =
    match r with
    | Transition t -> (!t).rate
    | Grab g -> (!g).rate
    | AGrab ag -> (!ag).rate

                  
(* **** asymetric_grab *)
(* auxilary function used by try_grabs *)
(* Try the grab of a molecule by a pnet *)
                  
  let asymetric_grab mol pnet = 
    let grabs = Petri_net.get_possible_mol_grabs mol pnet
    in
    if not (grabs = [])
    then
      let grab,pid = random_pick_from_list grabs in
      match grab with
      | pos -> Petri_net.grab mol pos pid pnet
    else
      false
    
  let oasymetric_grab mol opnet =
    match opnet with
    | Some pnet -> asymetric_grab mol pnet
    | None -> failwith "oasymetric_grab @ bacterie.ml : there should be a pnet"
            
  let treat_reaction  (r : Reaction.t) :
        reaction_effect list =
    let effects = ref [] in
    match r with
    | Transition trans ->
       let pnet = (!trans).amd.pnet in
       let actions = Petri_net.launch_random_transition !pnet in
       Petri_net.update_launchables !pnet;
       effects :=
         Update (!trans).amd.reacs :: T_effects actions :: (!effects);
       !effects
       
    | Grab g ->
       let pnet =  !(g).graber_data.pnet in
       ignore (asymetric_grab (!g).grabed_data.mol !pnet);
       (!g).grabed_data.qtt := !((!g).grabed_data.qtt) -1;
       Petri_net.update_launchables !pnet;
       effects := Update (!g).grabed_data.reacs  ::
                    Update (!g).graber_data.reacs ::
                      (!effects);
       !effects
    (* we will need to take care of possible tokens inside the
        grabed  pnet *)
    | AGrab g ->
       let pnet =  !(g).graber_data.pnet in
       ignore (asymetric_grab (!g).grabed_data.mol !pnet);
       Petri_net.update_launchables !pnet;
       effects := Update (!g).grabed_data.reacs  ::
                    Update (!g).graber_data.reacs ::
                      Remove_pnet (!(g).grabed_data.mol,
                                   !(g).grabed_data.pnet)
                      ::   (!effects);
       !effects
       
  let unlink (r :t) =
    match r with
    | Transition t -> ()
    | Grab g ->    
         (* we remove reactions in both the graber and the grabed 
            even though only the graber can normally disappear,
            we allow the gui to remove inert molecules, plus it might
            help clean some stuff *)
       let ar = (!g).graber_data.reacs in
       ar := ReacsSet.remove r !ar; 
       let ir = (!g).grabed_data.reacs in
       ir := ReacsSet.remove r !ir;         
    | AGrab ag ->
       let ar = (!ag).graber_data.reacs in
       ar := ReacsSet.remove r !ar; 
       let ir = (!ag).grabed_data.reacs in
       ir := ReacsSet.remove r !ir;
                   
end
  
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

   end
         
module GrabsSet =
  struct 
    include Set.Make (struct
                       type t = Reaction.grab
                       let compare =  Reaction.compare_grab
                     end)
          
    let show (gs :t) =
           fold (fun (g : Reaction.grab) desc ->
               (Reaction.show_grab g)^"\n"^desc)
                gs
                ""
  end
                          
module AGrabsSet =
  struct
    include Set.Make (struct
                       type t = Reaction.agrab
                       let compare =  Reaction.compare_agrab
                     end)
          
    let show (ags :t) =
      fold (fun (ag : Reaction.agrab) desc ->
          (Reaction.show_agrab ag)^"\n"^desc)
           ags
                ""
  end
                          
module TransitionsSet =
  struct
  include 
    Set.Make (struct
               type t = Reaction.transition
               let compare = Reaction.compare_transition
             end)
  let show (ts : t) =
      fold (fun (t : Reaction.transition) desc ->
          (Reaction.show_transition t)^"\n"^desc)
           ts
           ""
  end
  
