
open Misc_library


     
module type REACTANTS =
  sig
    type effect
       
    module type REACTANT_DEFAULT =
      sig
        type t
        type reac
        val show : t -> string
        val pp : Format.formatter -> t -> unit
        val compare : t -> t -> int
        val add_reac : reac -> t -> unit
        val qtt : t -> float
        val mol : t -> Molecule.t
      end

      
    module AMOL :
    sig
      include REACTANT_DEFAULT
      val grab : Molecule.t -> t -> effect list
      val grab_factor : Molecule.t -> t -> float
      val transition_factor : t -> float
      val launch_transition : t -> effect list
    end
      
    module IMOLSET :
      sig
        include REACTANT_DEFAULT
      end

    type t =
      | Amol of AMOL.t
      | ImolSet of IMOLSET.t
    val show : t -> string
    val pp : Format.formatter -> t -> unit
    val compare : t -> t -> int
                 
  end
  

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
  

  
module ReactionsM (R : REACTANTS) =
  struct
    type effect =
      | R_effects of R.effect list
                              (* handles the side effects of removing
                                 an element, e.g. removing a pnet
                                 will release the tokens
                                 (this means the tokens won't interact
                                 with the grabing molecule ? *)
      | Remove_one of R.t
      | Update_reacs of R.t
      | Release_mol of Molecule.t
                    
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
      end
      
                    
    module Grab :
    (REAC with type build_t = (R.AMOL.t ref * R.t ref)) =
      struct
        type t =  {
            mutable rate : float;
            graber_data : R.AMOL.t ref;
            grabed_data : R.t ref;
          }
                    [@@ deriving show, ord]
                
        type build_t = (R.AMOL.t ref * R.t ref)
                            
        let calculate_rate ({graber_data; grabed_data;_} : t) =
          let (mol,qtt) = match !grabed_data with
            | Amol amol -> (R.AMOL.mol amol, R.AMOL.qtt amol)
            | ImolSet ims -> (R.IMOLSET.mol ims, R.IMOLSET.qtt ims) in
         (R.AMOL.grab_factor
            mol
            !graber_data) *.
           qtt 
          
        let rate ({rate;_} : t) : float=
          rate
          
        let update_rate (({rate;_}) as g : t) =
          let old_rate = rate in
          g.rate <- calculate_rate g;
          g.rate -. old_rate
          
        let make ((graber_data, grabed_data) : build_t) : t=
          {graber_data; grabed_data;
           rate = calculate_rate ({graber_data; grabed_data; rate=0.})}
          
        let eval (g : t) : effect list =
          let mol = match !(g.grabed_data) with
            | Amol amol -> R.AMOL.mol amol
            | ImolSet ims -> R.IMOLSET.mol ims in
          
          Remove_one !(g.grabed_data):: 
            R_effects (R.AMOL.grab
                         mol
                         !(g.graber_data)) ::
              Update_reacs (Amol !(g.graber_data)) ::
                Update_reacs !(g.grabed_data) ::
                  []
      end


      
    module Transition  :
    (REAC with type build_t = R.AMOL.t ref)
      =
      struct
        type t = {
            mutable rate : float;
            amd : R.AMOL.t ref;
          }
                   [@@ deriving ord, show]
               
        type build_t = R.AMOL.t ref
                     
        let calculate_rate (t :t)  =
          R.AMOL.transition_factor !(t.amd)
          
        let rate (t : t)  =
          t.rate
          
        let update_rate (({rate;_}) as t : t) =
          let old_rate = rate in
          t.rate <- calculate_rate t;
          t.rate -. old_rate
          
        let make (amd : build_t)  =
          { rate = calculate_rate {amd; rate = 0.}; amd; }
          
        let eval (trans : t) : effect list= 
          R_effects (R.AMOL.launch_transition !(trans.amd)) ::
            Update_reacs (Amol !(trans.amd)) ::
              []
      
      
      end
      
    module Break :
    (REAC with type build_t = (R.t ref)) =
      struct
        type t = {mutable rate : float;
                  reactant : R.t ref;}
                   [@@ deriving show, ord]
               
        type build_t = R.t ref
                    
        let calculate_rate ba =
          let mol = match !(ba.reactant) with
            | Amol amol -> R.AMOL.mol amol
            | ImolSet ims -> R.IMOLSET.mol ims in
          sqrt (float_of_int (String.length mol - 1))
          
        let rate ba =
          ba.rate
          
        let update_rate ba = 
          let old_rate = ba.rate in
          ba.rate <- calculate_rate ba;
          ba.rate -. old_rate
          
        let make reactant =
          {reactant; rate = calculate_rate {reactant; rate = 0.}}
          
        let eval ba =
          let mol = match !(ba.reactant) with
            | Amol amol -> R.AMOL.mol amol
            | ImolSet ims -> R.IMOLSET.mol ims in
          let (m1, m2) = Molecule.break mol in
          Remove_one !(ba.reactant) ::
            Update_reacs !(ba.reactant) ::
              Release_mol m1 ::
                Release_mol m2 ::
                  []
      end
      
  end
