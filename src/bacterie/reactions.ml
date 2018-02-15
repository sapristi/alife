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
    type reacsSet
       
    type inert_md =   {mol : Molecule.t;
                       qtt : int ref;
                       reacs : reacsSet ref;}
    val show_inert_md : inert_md -> string
    val pp_inert_md : Format.formatter -> inert_md -> unit
    val compare_inert_md : inert_md -> inert_md -> int
      
    type active_md = { mol : Molecule.t;
                       pnet : Petri_net.t ref;
                       reacs : reacsSet ref;}

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

module type REAC =
  sig
    type t
    type build_t
    type reacsSet
    type effect
    val show : t -> string
    val pp : Format.formatter -> t -> unit
    val compare : t -> t -> int
    val calculate_rate : build_t -> float
    val rate : t -> float
    val make : build_t -> t
    val linked_reacs : t -> reacsSet
    val eval : t -> effect list
  end

module GrabM (MD : MOLDATA) : REAC =
  struct
    
      type t =  {
            mutable rate : float;
            graber_data : MD.active_md;
            grabed_data : MD.inert_md;
          }
                                 [@@ deriving ord, show]

             
      type build_t = (MD.active_md * MD.inert_md)
      type reacsSet = MD.reacsSet
      type effect = MD.reaction_effect
                   
      let calculate_rate ((amd,imd) : build_t) =
        float_of_int (Petri_net.grab_factor imd.mol !(amd.pnet)) *.
          float_of_int !(imd.qtt) 
        
      let rate ({rate;_} : t) : float=
        rate
        
      let make ((amd, imd) : build_t) : t=
        {graber_data = amd; grabed_data = imd;
         rate = calculate_rate (amd,imd)} 
        
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
  end


module AGrabM (MD : MOLDATA) : REAC =
  struct
    
      type t = {
          mutable rate : float;
          graber_data : MD.active_md;
          grabed_data : MD.active_md;
        }  
                 [@@ deriving ord, show]
             
      type build_t = (MD.active_md*MD.active_md)
      type reacsSet = MD.reacsSet
      type effect = MD.reaction_effect
                  
      let calculate_rate ((graber_d,grabed_d) : build_t) =
        1.
      let rate (ag : t) = ag.rate
                                
      let make ((graber_data, grabed_data) : build_t) : t =    {
          rate = calculate_rate (graber_data, grabed_data);
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

       
    end          


module TransitionM (MD : MOLDATA) : REAC =
  struct
    type t = {
        mutable rate : float;
        amd : MD.active_md;
      }
               [@@ deriving ord, show]
           
    type build_t = MD.active_md
    type reacsSet = MD.reacsSet
    type effect = MD.reaction_effect
    let calculate_rate (amd : build_t)  =
      (float_of_int !(amd.pnet).launchables_nb)
      
    let rate (t : t)  =
      t.rate
      
    let make (amd : MD.active_md)  =
      {
        rate = calculate_rate amd;
        amd;
      }

    let linked_reacs (t : t) =
      !(t.amd.reacs)
                 
    let eval (trans : t) : MD.reaction_effect list= 
      let pnet = !(trans.amd.pnet) in
      let actions = Petri_net.launch_random_transition pnet in
      Petri_net.update_launchables pnet;
      MD.Update_reacs (linked_reacs trans) ::
        MD.T_effects actions :: []
  end
