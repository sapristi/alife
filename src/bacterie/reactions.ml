
open Misc_library


     
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
      val make_new : ?ambient:bool -> Molecule.t -> t
      val add_to_qtt : int -> t -> t
      val set_qtt : int ->  t -> t
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
  

  
module ReactionsM (R : REACTANT) =
  struct
    type effect =
      | T_effects of Place.transition_effect list
      | Remove_one of R.t
      | Update_reacs of R.reacSet
      | Release_mol of Molecule.t
      | Release_tokens of Token.t list
      | RandomCollision
                     
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
        val remove_reac_from_reactants : R.reac -> t -> unit
      end
      
                    
    module Grab :
    (REAC with type build_t = (R.Amol.t ref * R.t)) =
      struct
        type t =  {
            mutable rate : float;
            graber_data : R.Amol.t ref;
            grabed_data : R.t;
          }
                    [@@ deriving show, ord]
                
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
            Update_reacs (R.Amol.reacs !(g.graber_data)) ::
              Update_reacs (R.reacs g.grabed_data) ::
                []
        let remove_reac_from_reactants reac g =
          R.Amol.remove_reac reac !(g.graber_data);
          R.remove_reac reac (g.grabed_data);
      end


      
    module Transition  :
    (REAC with type build_t = R.Amol.t ref)
      =
      struct
        type t = {
            mutable rate : float;
            amd : R.Amol.t ref;
          }
                   [@@ deriving ord, show]
               
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
          Petri_net.update_launchables (!(trans.amd).pnet);
          T_effects (t_effects) ::
            Update_reacs (R.Amol.reacs !(trans.amd)) ::
              []
      
      
        let remove_reac_from_reactants reac g =
          ()
      end
      
    module Break :
    (REAC with type build_t = (R.t)) =
      struct
        type t = {mutable rate : float;
                  reactant : R.t;}
                   [@@ deriving show, ord]
               
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
            Update_reacs (R.reacs ba.reactant) ::
              Release_mol m1 ::
                Release_mol m2 ::
                  []
          
          
        let remove_reac_from_reactants reac g =
          ()
      end

    module RandomCollision:
    (REAC with type build_t = (int ref))
      =
      struct
        type t = {mutable rate : float;
                  total_mol_qtt : int ref}

        let compare rc1 rc2 = 0
        type build_t = int ref
        let show (rc : t) =
          Printf.sprintf "RandomCollision (rate = %f)" rc.rate
        let pp f rc =
          Format.pp_print_string f (show rc)

        let calculate_rate (total_mol_qtt:build_t) =
          float_of_int (!total_mol_qtt
                        * !total_mol_qtt)
        let rate rc =
          rc.rate

        let update_rate rc = 
          let old_rate = rc.rate in
          rc.rate <- calculate_rate rc.total_mol_qtt;
          rc.rate -. old_rate

        let make (total_mol_qtt : int ref) =
          {rate = calculate_rate total_mol_qtt;
           total_mol_qtt}

        let eval rc =
          [RandomCollision]

        let remove_reac_from_reactants reac rc = ()
          
      end
      (* another idea for random collisions : 
         they take as build_t int ref * (unit -> R.t) * (unit -> R.t)
         so that when the reaction happens they will fetch a random 
         reactant from the bactery
         This allows to define everything in the module without knowing the
         type of a bactery.    
         The reaction is initialised with functions provided by the bactery
         to fetch a random reactant. 
       *) 
    module RandomCollisionBis:
    (REAC with type build_t = (int ref))
      =
      struct
        type t = {mutable rate : float;
                  total_mol_qtt : int ref}

        let compare rc1 rc2 = 0
        type build_t = int ref
        let show (rc : t) =
          Printf.sprintf "RandomCollision (rate = %f)" rc.rate
        let pp f rc =
          Format.pp_print_string f (show rc)

        let calculate_rate (total_mol_qtt:build_t) =
          float_of_int (!total_mol_qtt
                        * !total_mol_qtt)
        let rate rc =
          rc.rate

        let update_rate rc = 
          let old_rate = rc.rate in
          rc.rate <- calculate_rate rc.total_mol_qtt;
          rc.rate -. old_rate

        let make (total_mol_qtt : int ref) =
          {rate = calculate_rate total_mol_qtt;
           total_mol_qtt}

        let eval rc =
          [RandomCollision]

        let remove_reac_from_reactants reac rc = ()
          
      end
  end
