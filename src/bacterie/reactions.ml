open Molecule
open Petri_net
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
    type _ reac
    type reacSet 
    module Active :
    sig
      type t = {
          mol : Molecule.t;
          pnet : Petri_net.t ref;
          reacs : reacSet ref; 
        }
      val show : t -> string
      val pp : Format.formatter -> t -> unit
      val compare : t -> t -> int
      val add_reac : _ reac -> t -> unit
      val make_new : Petri_net.t ref -> t
    end
         
    module Inert :
    sig
      type t = {
          mol : Molecule.t;
          qtt : int ref; 
          reacs : reacSet ref; 
        }
      val show : t -> string
      val pp : Format.formatter -> t -> unit
      val compare : t -> t -> int
      val add_reac : _ reac -> t -> unit
      val make_new : Molecule.t -> int ref -> t
    end
    val union : reacSet -> reacSet -> reacSet
       
    type reaction_effect =
      | T_effects of Place.transition_effect list
      | Remove_pnet of Active.t
      | Update_reacs of reacSet
      | Modify_quantity of Inert.t * int
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
    val make : build_t -> t
    val rate : t -> float
    val update_rate : t -> float
    val linked_reacs : t -> reacSet
    val linked_reacSets : t -> reacSet ref list
    val eval : t -> effect list
  end

module GrabM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Active.t * MD.Inert.t)
       and type effect = MD.reaction_effect) =
  struct
    type t =  {
        mutable rate : float;
        graber_data : MD.Active.t;
        grabed_data : MD.Inert.t;
      }
            [@@ deriving show, ord]
               
            
    type build_t = (MD.Active.t * MD.Inert.t)
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
                
    let calculate_rate ({graber_data; grabed_data;_} : t) =
      float_of_int (Petri_net.grab_factor
                      grabed_data.mol
                      !(graber_data.pnet)) *.
        float_of_int !(grabed_data.qtt) 
      
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
        MD.union !(g.graber_data.reacs)
                 !(g.grabed_data.reacs)

      let eval (g : t) : MD.reaction_effect list= 
        ignore (asymetric_grab g.grabed_data.mol !(g.graber_data.pnet));
        Petri_net.update_launchables
          !(g.graber_data.pnet);
        MD.Modify_quantity ( g.grabed_data, -1) ::
          MD.Update_reacs (linked_reacs g) ::
              []
        
    (* we will need to take care of possible tokens inside the
        grabed  pnet *)

      let linked_reacSets (g : t) =
        [(g.graber_data.reacs); (g.grabed_data.reacs)]
  end


module AGrabM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = (MD.Active.t * MD.Active.t)
       and type effect = MD.reaction_effect)
  =
  struct
    
    type t = {
        mutable rate : float;
        graber_data : MD.Active.t;
        grabed_data : MD.Active.t;
      }  
               [@@ deriving ord, show]
           
    type build_t = (MD.Active.t*MD.Active.t)
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
                
    let calculate_rate ({graber_data;grabed_data;_} : t) =
      1.
    let rate (ag : t) = ag.rate
                      
    let update_rate (({rate;_}) as ag : t) =
      let old_rate = rate in
      ag.rate <- calculate_rate ag;
      ag.rate -. old_rate
      
    let make ((graber_data, grabed_data) : build_t) : t =    {
        rate = calculate_rate {graber_data; grabed_data;rate = 0.};
        graber_data;
        grabed_data;}
                                                           
    let linked_reacs (ag : t) =
      MD.union !(ag.graber_data.reacs)
               !(ag.grabed_data.reacs)
      
      
    let eval (ag : t) : MD.reaction_effect list = 
      
      ignore (asymetric_grab
                (ag.grabed_data.mol)
                !(ag.graber_data.pnet));
      Petri_net.update_launchables
        !(ag.graber_data.pnet);
      MD.Remove_pnet ag.grabed_data ::
        MD.Update_reacs !(ag.grabed_data.reacs) ::
          MD.Update_reacs  (linked_reacs ag) ::
            []
      
    let linked_reacSets (g : t) =
      [(g.graber_data.reacs); (g.grabed_data.reacs)]
       
    end          


module TransitionM (MD : MOLDATA) :
(REAC with type reacSet = MD.reacSet
       and type build_t = MD.Active.t
       and type effect = MD.reaction_effect)
  =
  struct
    type t = {
        mutable rate : float;
        amd : MD.Active.t;
      }
               [@@ deriving ord, show]
           
    type build_t = MD.Active.t
    type reacSet = MD.reacSet
    type effect = MD.reaction_effect
    let calculate_rate ({amd; _} :t)  =
      (float_of_int !(amd.pnet).launchables_nb)
      
    let rate (t : t)  =
      t.rate
      
    let make (amd : MD.Active.t)  =
      {
        rate = calculate_rate {amd; rate = 0.};
        amd;
      }
                      
    let update_rate (({rate;_}) as t : t) =
      let old_rate = rate in
      t.rate <- calculate_rate t;
      t.rate -. old_rate
      
    let linked_reacs (t : t) =
      !(t.amd.reacs)
                 
    let eval (trans : t) : MD.reaction_effect list= 
      let pnet = !(trans.amd.pnet) in
      let actions = Petri_net.launch_random_transition pnet in
      Petri_net.update_launchables pnet;
      MD.Update_reacs (linked_reacs trans) ::
        MD.T_effects actions :: []

      
    let linked_reacSets (g : t) =
        [(g.amd.reacs);]
  end
