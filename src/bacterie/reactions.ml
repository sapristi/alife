
open Local_libs.Misc_library


(* * file overview *)

(*   Defines a functor that takes a Reactant module and makes reactions out *)
(*   of it. Possible reactions are : *)
  
(*   + Grab : *)
(*     grab between an active molecule and another reactant *)

(*   + Transition : *)
(*     launches a transition in an active molecule *)
    
(*   + Break : *)
(*     a molecules breaks in two pieces *)

(* ** Reaction general *)

(*    A reaction is a record with : *)
(*    + for each reactant, a field with a reference to this reactant *)
(*    + a mutable rate field to store the rate *)
   
(*    In a reaction module, the following functions are defined *)
     
(*    + calculate_rate (not public) : *)
(*      calculates the rate at which the reaction takes place *)

(*    + rate : *)
(*      returns the value in rate field *)
     
(*    + update_rate : *)
(*      modifies rate field with a newly calculated value *)
(*      and returns the difference between old and new rate *)
(*      (for easy update of global rate) *)

(*    + make : creates the reaction from references to the reactants *)

(*    + eval : performs the reaction on the reactants and returns a list *)
(*      of actions to be performed at higher level *)

(* *** TODO tasks *)
(*     + clearly define what is to be done in eval *)
(*       and what is to be returned higher, and why *)

(* * REACTANT signature *)
  

module type REACTANT =
  sig
    type reac
    type reacSet
       
    module type REACTANT_DEFAULT =
      sig
        type t
        type reac
        type reacSet
        val show : t -> string
        val to_yojson : t -> Yojson.Safe.json
        val show_reacSet : reacSet -> string
        val pp_reacSet : Format.formatter -> reacSet -> unit
        val pp : Format.formatter -> t -> unit
        val compare : t -> t -> int
        val mol : t -> Molecule.t
        val qtt : t -> int
        val reacs : t -> reacSet
        val remove_reac : reac -> t -> unit
        val add_reac : reac -> t -> unit
      end
    module ImolSet :
    sig
      type t =
        private {
            mol : Molecule.t;
            qtt : int; 
            reacs : reacSet ref;
            ambient:bool;
          }
      val make_new : Molecule.t -> t
      val add_to_qtt : int -> t -> t
      val set_qtt : int ->  t -> t
      val set_ambient : bool -> t -> t
      include REACTANT_DEFAULT
              with type t := t
              and type reac := reac
              and type reacSet := reacSet
    end
         
    module Amol :
    sig
      type t =
        private {
            mol : Molecule.t;
            pnet : Petri_net.t;
            reacs : reacSet ref;
          }
      val make_new : Petri_net.t -> t
      include REACTANT_DEFAULT
              with type t := t
              and type reac := reac
              and type reacSet := reacSet
    end

         
    type t =
      | Amol of Amol.t ref
      | ImolSet of ImolSet.t ref

    include REACTANT_DEFAULT
            with type t := t
            and type reac := reac
            and type reacSet := reacSet
  end
  

(* * asymetric_grab auxiliary function *)
(*  Why is it not in the functor ?  *)

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
  
(* * ReactionsM functor *)
  
module ReactionsM (R : REACTANT) =
  struct
    type effect =
      | T_effects of Place.transition_effect list
      | Update_launchables of R.Amol.t ref
      | Remove_one of R.t
      | Update_reacs of R.reacSet
      | Remove_reacs of R.reacSet
      | Release_mol of Molecule.t
      | Release_tokens of Token.t list
               [@@deriving show]         
    module type REAC =
      sig
        type t
        type build_t
        val show : t -> string
        val to_yojson : t -> Yojson.Safe.json
        val pp : Format.formatter -> t -> unit
        val compare : t -> t -> int
        val rate : t -> float
        val update_rate : t -> float
        val make : build_t -> t
        val eval : t -> effect list
        val remove_reac_from_reactants : R.reac -> t -> unit
      end
      
(* ** Grab reaction *)                    
    module Grab :
    (REAC with type build_t = (R.Amol.t ref * R.t)) =
      struct
        type t =  {
            mutable rate : float;
            graber_data : R.Amol.t ref;
            grabed_data : R.t;
          }
                    [@@ deriving show, ord, to_yojson]
                
        type build_t = (R.Amol.t ref * R.t)
                     
        let calculate_rate ({graber_data; grabed_data;_} : t) =
          let mol = R.mol grabed_data
          and qtt = R.qtt grabed_data in
          float_of_int (Petri_net.grab_factor
             mol
             (!graber_data.pnet)) *.
            (float_of_int qtt) 
          
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
          ignore( asymetric_grab
            (R.mol (g.grabed_data))
            (!(g.graber_data).pnet));
          Remove_one (g.grabed_data)::
            Update_launchables g.graber_data :: 
              Update_reacs (R.Amol.reacs !(g.graber_data)) ::
                []
        let remove_reac_from_reactants reac g =
          R.Amol.remove_reac reac !(g.graber_data);
          R.remove_reac reac (g.grabed_data);
      end


(* **  Transition reaction *)                    
      
    module Transition  :
    (REAC with type build_t = R.Amol.t ref)
      =
      struct
        type t = {
            mutable rate : float;
            amd : R.Amol.t ref;
          }
                   [@@ deriving ord, show, to_yojson]
               
        type build_t = R.Amol.t ref
                     
        let calculate_rate (t :t)  =
          float_of_int (!(t.amd).pnet).launchables_nb
          
        let rate (t : t)  =
          t.rate
          
        let update_rate (({rate;_}) as t : t) =
          let old_rate = rate in
          t.rate <- calculate_rate t;
          t.rate -. old_rate
          
        let make (amd : build_t)  =
          { rate = calculate_rate {amd; rate = 0.}; amd; }
          
        let eval (trans : t) : effect list=
          let t_effects = Petri_net.launch_random_transition
                            (!(trans.amd).pnet)
          in
          (*          Petri_net.update_launchables (!(trans.amd).pnet);*)
          T_effects (t_effects) ::
            Update_launchables trans.amd ::
              Update_reacs (R.Amol.reacs !(trans.amd)) ::
                []
      
      
        let remove_reac_from_reactants reac g =
          ()
      end
      
(* **  Break reaction *)  
      
    module Break :
    (REAC with type build_t = (R.t)) =
      struct
        type t = {mutable rate : float; 
                  reactant : R.t; [@compare fun a b -> 0]
                 }
                   [@@ deriving show, ord, to_yojson]
               
        type build_t = R.t
                    
        let calculate_rate ba =
          let mol = R.mol (ba.reactant) in
          sqrt (float_of_int (String.length mol - 1)) *.
            (float_of_int (R.qtt (ba.reactant)))
          
        let rate ba =
          ba.rate
          
        let update_rate ba = 
          let old_rate = ba.rate in
          ba.rate <- calculate_rate ba;
          ba.rate -. old_rate
          
        let make reactant =
          {reactant; rate = calculate_rate {reactant; rate = 0.}}
          
        let eval ba =
          let mol = R.mol (ba.reactant)  in
          let (m1, m2) = Molecule.break mol in
          Remove_one (ba.reactant) ::
              Release_mol m1 ::
                Release_mol m2 ::
                  []
          
          
        let remove_reac_from_reactants reac g =
          ()
      end

  end
