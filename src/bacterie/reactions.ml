
open Misc_library


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
  
module type MOLDATA =
  sig
    type reac
    type reacSet 
    module Inert :
    sig
      type t = {
          mol : Molecule.t;
          qtt : int; 
          reacs : reacSet ref; 
        }
      val show : t -> string
      val pp : Format.formatter -> t -> unit
      val compare : t -> t -> int
      val add_reac : reac -> t -> unit
      val make_new : Molecule.t -> int -> t
    end
    module Active :
    sig
      type t = {
          mol : Molecule.t;
          pnet : Petri_net.t;
          (* reacs needs to be a ref because we modify
             it externally with unlink *)
          reacs : reacSet ref; 
        }
      val show : t -> string
      val pp : Format.formatter -> t -> unit
      val compare : t -> t -> int
      val add_reac : reac -> t -> unit
      val make_new : Petri_net.t -> t
    end
(*
    module ASet : Batteries.Set.S with type elt = (Active.t ref)
    module ActiveSet :
    sig
      type t = {
          mol : Molecule.t;
          qtt : int;
          reacs : reacSet ref;
          pnets : ASet.t;
        }
      val show : t -> string
      val pp : Format.formatter -> t -> unit
      val compare : t -> t -> int
      val add_reac : reac -> t -> unit
      val make_new : Molecule.t -> t
    end *)
    val union : reacSet -> reacSet -> reacSet
      
    type reaction_effect =
      | T_effects of Place.transition_effect list
      | Remove_pnet of Active.t ref
      | Update_reacs of reacSet
      | Modify_quantity of Inert.t ref * int
      | Release_tokens of Token.t list
      | Release_mol of Molecule.t
  end

module type REAC =
  sig
    type t
    type build_t
    type reacSet
    type effect
    val show : t -> string
    val pp : Format.formatter -> t -> unit
    val compare : t -> t -> int
    val rate : t -> float
    val update_rate : t -> float
    val make : build_t -> t
    val linked_reacs : t -> reacSet
    val linked_reacSets : t -> reacSet ref list
    val eval : t -> effect list
  end

module GrabM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Active.t ref * MD.Inert.t ref)
       and type effect = MD.reaction_effect) =
  struct
    type t =  {
        mutable rate : float;
        graber_data : MD.Active.t ref;
        grabed_data : MD.Inert.t ref;
      }
            [@@ deriving show, ord]
               
    type build_t = (MD.Active.t ref * MD.Inert.t ref)
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
                
    let calculate_rate ({graber_data; grabed_data;_} : t) =
      float_of_int (Petri_net.grab_factor
                      !grabed_data.mol
                      !graber_data.pnet) *.
        float_of_int !grabed_data.qtt 
      
    let rate ({rate;_} : t) : float=
      rate

    let update_rate (({rate;_}) as g : t) =
      let old_rate = rate in
      g.rate <- calculate_rate g;
      g.rate -. old_rate
      
    let make ((graber_data, grabed_data) : build_t) : t=
      {graber_data; grabed_data;
       rate = calculate_rate ({graber_data; grabed_data; rate=0.})}
      
    let linked_reacs (g : t) =
      (* we remove reactions in both the graber and the grabed 
            even though only the graber can normally disappear,
            we allow the gui to remove inert molecules, plus it might
            help clean some stuff *)
        MD.union !(!(g.graber_data).reacs)
                 !(!(g.grabed_data).reacs)

    let linked_reacSets (g : t) =
      [(!(g.graber_data).reacs); (!(g.grabed_data).reacs)]

        
      let eval (g : t) : MD.reaction_effect list= 
        ignore (asymetric_grab !(g.grabed_data).mol
                               !(g.graber_data).pnet);
        Petri_net.update_launchables
          !(g.graber_data).pnet;
        MD.Modify_quantity ( g.grabed_data, -1) ::
          MD.Update_reacs (linked_reacs g) ::
              []
        

  end


module AGrabM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Active.t ref * MD.Active.t ref)
       and type effect = MD.reaction_effect)
  =
  struct
    
    type t = {
        mutable rate : float;
        graber_data : MD.Active.t ref;
        grabed_data : MD.Active.t ref;
      }  
               [@@ deriving ord, show]
           
    type build_t = (MD.Active.t ref * MD.Active.t ref)
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
                
    let calculate_rate ({graber_data;grabed_data;_} : t) =
      1.
    let rate (ag : t) = ag.rate
                      
    let update_rate (({rate;_}) as ag : t) =
      let old_rate = rate in
      ag.rate <- calculate_rate ag;
      ag.rate -. old_rate
      
    let make ((graber_data, grabed_data) : build_t) : t =
      { rate = calculate_rate {graber_data; grabed_data;rate = 0.};
        graber_data;
        grabed_data;}
                                                           
    let linked_reacs (ag : t) =
      MD.union !(!(ag.graber_data).reacs)
               !(!(ag.grabed_data).reacs)
      
    let linked_reacSets (g : t) =
      [!(g.graber_data).reacs; !(g.grabed_data).reacs]
      
    let eval (ag : t) : MD.reaction_effect list = 
      
      ignore (asymetric_grab
                !(ag.grabed_data).mol
                !(ag.graber_data).pnet);
      Petri_net.update_launchables
        !(ag.graber_data).pnet;

      let grabed_pnet = !(ag.grabed_data).pnet in
      let poped_tokens = Petri_net.get_tokens grabed_pnet in
      
      MD.Remove_pnet (ag.grabed_data) ::
        MD.Update_reacs  (linked_reacs ag) ::
          MD.Release_tokens poped_tokens ::
            []
      
       
    end          


module TransitionM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = MD.Active.t ref
       and type effect = MD.reaction_effect)
  =
  struct
    type t = {
        mutable rate : float;
        amd : MD.Active.t ref;
      }
               [@@ deriving ord, show]
           
    type build_t = MD.Active.t ref
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
                
    let calculate_rate ({amd; _} :t)  =
      (float_of_int !amd.pnet.launchables_nb)
      
    let rate (t : t)  =
      t.rate
      
    let update_rate (({rate;_}) as t : t) =
      let old_rate = rate in
      t.rate <- calculate_rate t;
      t.rate -. old_rate
      
    let make (amd : build_t)  =
      { rate = calculate_rate {amd; rate = 0.}; amd; }
      
    let linked_reacs (t : t) =
      !(!(t.amd).reacs)
    let linked_reacSets (g : t) =
        [!(g.amd).reacs;]
                 
    let eval (trans : t) : MD.reaction_effect list= 
      let pnet = !(trans.amd).pnet in
      let actions = Petri_net.launch_random_transition pnet in
      Petri_net.update_launchables pnet;
      MD.Update_reacs (linked_reacs trans) ::
        MD.T_effects actions :: []

      
  end

module BreakAM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Active.t ref)
       and type effect = MD.reaction_effect) =
  struct
    type t = {mutable rate : float;
              amd : MD.Active.t ref;}
               [@@ deriving show, ord]

    type build_t = MD.Active.t ref
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
           
    let calculate_rate ba =
      float_of_int (String.length !(ba.amd).mol - 1)

    let rate ba =
      ba.rate

    let update_rate ba = 
      let old_rate = ba.rate in
      ba.rate <- calculate_rate ba;
      ba.rate -. old_rate

    let make amd =
      {amd; rate = calculate_rate {amd; rate = 0.}}

    let linked_reacs (ba : t) =
      !(!(ba.amd).reacs)
      
    let linked_reacSets (ba : t) =
        [!(ba.amd).reacs;]

    let eval ba =
      let (m1, m2) = Molecule.break !(ba.amd).mol in
      
      let broken_pnet = !(ba.amd).pnet in
      let poped_tokens = Petri_net.get_tokens broken_pnet in

      
      MD.Remove_pnet (ba.amd) ::
        MD.Update_reacs (linked_reacs ba) ::
          MD.Release_mol m1 ::
            MD.Release_mol m2 ::
              MD.Release_tokens poped_tokens ::
                []
  end

module BreakIM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Inert.t ref)
       and type effect = MD.reaction_effect) =
  struct
    type t = {mutable rate : float;
              imd : MD.Inert.t ref;}
               [@@ deriving show, ord]
           
    type build_t = MD.Inert.t ref
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
           
    let calculate_rate ba =
      float_of_int (String.length !(ba.imd).mol - 1)
      *. (float_of_int !(ba.imd).qtt)
    let rate ba =
      ba.rate

    let update_rate ba = 
      let old_rate = ba.rate in
      ba.rate <- calculate_rate ba;
      ba.rate -. old_rate

    let make imd =
      {imd; rate = calculate_rate {imd; rate = 0.}}

    let linked_reacs (ba : t) =
      !(!(ba.imd).reacs)
      
    let linked_reacSets (ba : t) =
        [!(ba.imd).reacs;]

    let eval ba =
      let (m1, m2) = Molecule.break !(ba.imd).mol in
      
      
      MD.Modify_quantity (ba.imd, -1) ::
        MD.Update_reacs (linked_reacs ba) ::
          MD.Release_mol m1 ::
            MD.Release_mol m2 ::
              []
  end
