open Reactions
open Yojson
open Local_libs
open Numeric
open Base_chemistry
open Local_libs.Misc_library
(* * file overview *)

(* ** Reactant module *)

(*    Reactant.t is defined as a sum type of various possible reactants, *)
(*    Reactants can be : *)

(*     + ImolSet contains inactive molecules, that is molecules that could not *)
(*       be folded into a petri net (or possible molecules with degenerate petri nets) *)

(*     + Amol contains a unique active molecule, with the associated petri net *)

(*     + ASet (work in progress) is intended to hold a set of active molecules. *)
(*       (the molecule would be unique, but petri nets in various states could be *)
(*       present). It is still unknown if a good implementation is possible, because *)
(*       we would need to know about the rates of this set in a reaction, which *)
(*       depends on the internal state of the contained petri nets. *)

(* ** Reacs module *)
(*    Application of the functor defined in reactions.ml to the Reactant module. *)

(* ** Reaction module *)
(*    Reaction.t is a sum type, each case represents a reaction *)

(* ** ReacSet module *)
(*    Simply a Set of reactions *)


(* ** Explanation *)
(*   Since  reactants  hold themselves a set of reactions (whom rates have to be *)
(*   updated at a change in the reactant), the modules Reaction, ReacSet *)
(*   and Reactant are mutally dependant and have to be defined together. *)

(* * modules definitions*)
module rec

(* ** Reactant : contains a reactant (ImolSet or Amol or Aset) *)

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

(* *** ImolSet : reactant with inert molecules *)

    module ImolSet =
      struct
        type t = {
            mol : Molecule.t;
            mutable qtt : int;
            reacs : ReacSet.t ref;
            mutable ambient:bool;
          }

        let show (imd : t) =
          Printf.sprintf "Inert[%d] %s " imd.qtt imd.mol

        let pp (f : Format.formatter) (imd : t) =
          Format.pp_print_string f (show imd)
        let to_yojson (imd : t) : Yojson.Safe.t =
          `Assoc [ "mol" , Molecule.to_yojson imd.mol;
                   "qtt" , `Int  imd.qtt;
                   "ambient" , `Bool imd.ambient ]

        let show_reacSet = ReacSet.show
        let pp_reacSet = ReacSet.pp

        let compare (imd1 : t) (imd2 : t) =
          Molecule.compare imd1.mol imd2.mol
        let mol ims = ims.mol
        let qtt ims = ims.qtt
        let reacs ims = !(ims.reacs)
        let add_to_qtt deltaqtt ims =
          if not ims.ambient
          then ims.qtt <- ims.qtt + deltaqtt

        let set_qtt qtt (ims : t)=
          ims.qtt <- qtt
        let make_new mol : t =
          {mol; qtt=1; reacs = (ref ReacSet.empty);ambient=false}
        let copy ims =
          {mol= ims.mol; qtt = ims.qtt; reacs= ref !(ims.reacs); ambient= ims.ambient}
        let add_reac (reac : Reaction.t) (imd : t) =
          imd.reacs := ReacSet.add reac !(imd.reacs)
        let remove_reac (reac : Reaction.t) (imd : t) =
          imd.reacs := ReacSet.remove reac !(imd.reacs)
        let set_ambient ambient ims =
          ims.ambient <- ambient

      end

(* *** Amol :    reactant with one active molecule *)
    module Amol =
      struct
        type t = {
            mol : Molecule.t;
            pnet : Petri_net.t;
            reacs : ReacSet.t ref;
          }
        let show am =
          Printf.sprintf "Active[id:%d] %s" am.pnet.uid am.mol
        let to_yojson am : Yojson.Safe.t =
          `Assoc [ "mol", Molecule.to_yojson am.mol;
                   "pnet_id", `Int am.pnet.uid]
        let pp f am =
          Format.pp_print_string f (show am)

        let show_reacSet = ReacSet.show
        let pp_reacSet = ReacSet.pp
        let mol am =  am.mol
        let qtt am = 1
        let reacs am = !(am.reacs)
        let pnet am = am.pnet
        let make_new  (pnet : Petri_net.t) =
          {mol = pnet.mol; pnet; reacs = ref ReacSet.empty}

        let add_reac reac (amd : t) =
          amd.reacs := ReacSet.add reac !(amd.reacs)

        let remove_reac (reac : Reaction.t) (amd : t) =
          amd.reacs := ReacSet.remove reac !(amd.reacs)
        let compare
              (amd1 : t) (amd2 : t) =
          Pervasives.compare amd1.pnet.Petri_net.uid amd2.pnet.Petri_net.uid

      end
(* *** (ASet) :    reactant with active molecules set *)
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
(* *** Reactant functions *)
    type t =
      | Amol of Amol.t
      | ImolSet of ImolSet.t
      | Dummy
                     [@@ deriving show, ord, to_yojson]

    (* let to_yojson reactant =
     *   match reactant with
     *   | Amol amol -> `Assoc ["Amol", Amol.to_yojson amol]
     *   | ImolSet ims -> `Assoc["ImolSet", ImolSet.to_yojson ims]
     *   | Dummy -> `String "Dummy" *)
    let show_reacSet = ReacSet.show
    let pp_reacSet = ReacSet.pp
    let qtt reactant =
      match reactant with
      | Amol amol -> Amol.qtt amol
      | ImolSet ims -> ImolSet.qtt ims
    let mol reactant =
      match reactant with
      | Amol amol -> Amol.mol amol
      | ImolSet ims -> ImolSet.mol ims
    let reacs reactant =
      match reactant with
      | Amol amol -> Amol.reacs amol
      | ImolSet ims -> ImolSet.reacs ims
    let add_reac reaction reactant =
      match reactant with
      | Amol amol -> Amol.add_reac reaction amol
      | ImolSet ims -> ImolSet.add_reac reaction ims
    let remove_reac reaction reactant =
      match reactant with
      | Amol amol -> Amol.remove_reac reaction amol
      | ImolSet ims -> ImolSet.remove_reac reaction ims
  end

(* ** Reacs : implementation of the reactions *)

(*    We need to copy the entire signature because we use the recursively *)
(*    defined Reactant. *)
(*    See reactions.ml for more details. *)

   and Reacs :
         (sig

           type effect =
             | T_effects of Place.transition_effect list
             | Update_launchables of Reactant.Amol.t
             | Remove_one of Reactant.t
             | Update_reacs of Reactant.reacSet
             | Remove_reacs of Reactant.reacSet
             | Release_mol of Molecule.t
             | Release_tokens of Token.t list
                               [@@deriving show]
           module type REAC =
             sig
               type t
               type build_t
               val show : t -> string
               val to_yojson : t -> Yojson.Safe.t
               val pp : Format.formatter -> t -> unit
               val compare : t -> t -> int
               val rate : t -> Q.t
               val update_rate : t -> Q.t
               val make : build_t -> t
               val eval : Random_s.t -> t -> effect list
               val remove_reac_from_reactants : Reaction.t -> t -> unit
               val get_reactants: t -> build_t
             end

           module Grab :
           (REAC with type build_t = (Reactant.Amol.t *
                                        Reactant.t ))

           module Transition  :
           (REAC with type build_t = Reactant.Amol.t)


           module Break :
           (REAC with type build_t = (Reactant.t))

           module Collision :
             (REAC with type build_t = (Reactant.t * Reactant.t))


         end)
     = struct
     include ReactionsM(Reactant)
   end

(* ** Reaction  *)
   and Reaction :
         (sig

           type t  =
             | Grab of Reacs.Grab.t
             | Transition of Reacs.Transition.t
             | Break of Reacs.Break.t
             | Collision of Reacs.Collision.t

                      [@@deriving show]

           val to_yojson : t -> Yojson.Safe.t
           val treat_reaction : Random_s.t -> t -> Reacs.effect list
           val compare : t -> t -> int
           val unlink : t -> unit
         end)
     =
(* *** module definition *)
     struct
       open Reacs
       type t =
         | Grab of Grab.t
         | Transition of Transition.t
         | Break of Break.t
         | Collision of Collision.t

                      [@@ deriving ord, show, to_yojson]

       let rate r =
         match r with
         | Transition t -> Transition.rate t
         | Grab g -> Grab.rate g
         | Break b -> Break.rate b
         | Collision c -> Collision.rate c


       let treat_reaction randstate r  : effect list=
         match r with
         | Transition t -> Transition.eval randstate t
         | Grab g -> Grab.eval randstate g
         | Break b -> Break.eval randstate b
         | Collision c -> Collision.eval randstate c

       let unlink r =
         match r with
         | Transition t -> Transition.remove_reac_from_reactants r t
         | Grab g -> Grab.remove_reac_from_reactants r g
         | Break b -> Break.remove_reac_from_reactants r b
         | Collision c -> Collision.remove_reac_from_reactants r c
     end



 (* ** ReacSet module *)

   and ReacSet :
         (sig
           include CCSet.S with type elt =  Reaction.t
           val show : t -> string
           val to_yojson : t -> Yojson.Safe.t
           val pp : Format.formatter -> t -> unit
         end)
     =
     struct

       include CCSet.Make (Reaction)

       let show (rset :t) : string =
         fold (fun (reac : Reaction.t) desc ->
             (Reaction.show reac)^"\n"^desc)
           rset
           ""
       let to_yojson (rset :t) : Yojson.Safe.t=
         `List (List.map Reaction.to_yojson (to_list rset))
       let pp =
         pp ~start:"Reac set:\n" Reaction.pp
  end
