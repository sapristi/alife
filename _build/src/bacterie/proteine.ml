(*
#load "../build/misc_library.cmo";;
#load "../build/molecule.cmo";;
#directory "../build";;

#use "topfind";;
#require "batteries";;
*)

open Batteries
open Molecule
open Misc_library



open Types
open MyMolecule


type place_id = int;;
type transition_id = int;;

type token = moleculeHolder;;
let emptyToken = emptyHolder;;

(*  un holder est soit vide, soit il contient un unique token *)
type token_holder =
  | EmptyHolder
  | OccupiedHolder of token;;

type container = < send_message : string -> unit; add_molecule : molecule -> unit >;;



(* *************************************************************************
				place



   classe qui gère les places 
   Une place a un type, et peut contenir un jeton

   Initialisé seulement avec un type de place, 
   ne contient pas de jeton au début
*)
class place (placeType : place_type) =
       
object(self) 
  val mutable tokenHolder = 
    match placeType with
    | Initial_place -> OccupiedHolder emptyToken
    | _ -> EmptyHolder
       
  val placeType = placeType
    
  val mutable host : container option = None 

  method get_place_type = placeType

  method is_empty  : bool = tokenHolder = EmptyHolder
  
    (* enlève le token de la place *)
  method empty : unit = tokenHolder <- EmptyHolder
  
    (* met "brutalement" le token donné *)
  method set_token (t : token) : unit  =
    tokenHolder <- OccupiedHolder t
       
(* envoie un token dans la place, depuis une transition; 
   effectue donc les actions données par le type de place *)
  method send_token (t : token) : unit = 
    match placeType with
    
(* on doit relacher la molecule attachée au token
   pour l'instant, on ne fait que l'enlever, mais en vrai
   il faudrait l'ajouter à l'ensemble des molécules "libres" *)
    | Release_place -> 
       begin 
	 match tokenHolder with
	 | EmptyHolder -> ()
	 | OccupiedHolder t -> 
	    if t#is_empty
	    then 
	      
	      match host with
	      | None -> self#set_token emptyToken
	      | Some h -> h#add_molecule t#get_molecule;
		self#set_token emptyToken
	    else
	      ()
		
       end
    | Send_place s -> 
       begin
	 match host with
	 | None -> ()
	 | Some h -> h#send_message s
       end
	 
    | Displace_mol_place b -> 
       begin
	 match tokenHolder with
	 | EmptyHolder -> ()
	 | OccupiedHolder t -> 
	    if b 
	    then t#move_forward
	    else t#move_backward
       end
    | _ -> () 
    

  method pop_token : token = 
    match tokenHolder with
    | EmptyHolder -> failwith "pop without token"
    | OccupiedHolder t -> 
       self#empty;
      t
	
  method add_token_from_message  = 
    if not self#is_empty
    then
      tokenHolder <- EmptyHolder
    

  method add_token_from_binding (mol : molecule) : bool = 
    if self#is_empty
    then 
      false
    else
      begin
	tokenHolder <- OccupiedHolder (new moleculeHolder mol 0);
	true
      end

  method setHost h = host <- Some h
	
    

end




(*********************************************************************************
				transitions


classe qui gère les transitions 
*)
and  transition (places : place array) (depL : (place_id * input_link) list) (arrL : (place_id * output_link) list) =

(* fonction qui prends une liste d'arcs entrants 
   et une liste de tokens, et calcule le couple E, mols
   où E est l'énergie totale des tokens, et mols  est 
   la liste des molécules des tokens (qui ont potentiellement
   été coupées
*)
  let rec input_transition_function 
      (ill : input_link list)
      (tokens : token list)
      
      : (moleculeHolder list)
      
      =
    
    match tokens with
      
    | [] -> []
       
    | m :: tokens' -> 
       if m#is_empty
	 
       then 
	 input_transition_function (List.tl ill) tokens'
	   
       else 
	 match ill with
	   
	 | []  -> []
	    
	 | Regular_ilink ::ill' -> 
	    m ::  input_transition_function ill' tokens'
	      
	 | Split_ilink :: ill' -> 
	    let mol1, mol2 = m#cut in
	    mol1 :: mol2 :: input_transition_function ill' tokens'
 
	      

(* fonction qui prends une liste d'arcs entrants 
   une energie et une liste de molécukes, 
   et renvoie une liste de tokens
   Chaque token reçoit la moitié de l'énergie restante

   Attention : il faut bien garder la position précédente du token
*)
  and  output_transition_function 
      (oll : output_link list)
      (mols : moleculeHolder list)
      
      : token list 
      =
    
    match oll with
    | Regular_olink :: oll' -> 
       
     (* oui c'est plutot très moche comme manière de créer un token vide *)
       emptyToken :: output_transition_function oll'  mols
	 
    | Bind_olink :: oll' -> 
       begin
	 match mols with
	 | m1 ::  m2 :: mols' -> 
	    (m1#insert m2) :: output_transition_function oll' mols
	      
	 | m :: [] -> 
	    m  :: output_transition_function oll'  mols
	      
	 | [] -> 
	    (emptyHolder) :: output_transition_function oll' mols
       end
	 
    | Mol_output_olink :: oll' -> 
       begin
	 match mols with 
	 | m :: mols' -> 
	    m  :: output_transition_function oll'  mols
	      
	 | [] -> 
	    emptyToken :: output_transition_function oll'  mols
       end
    | [] -> []
       
  in
  let transition_function ill oll tokens = 
    output_transition_function oll (input_transition_function ill tokens)
      
  (* renvoie true ssi les places données en argument n'ont pas de jeton *)
  and places_are_free (places :  place array) (to_try : place_id list): bool =
    List.fold_left
      (fun res pId ->
	if places.(pId)#is_empty
	then res
	else false
      )
      true to_try
  in
  let dp, dl = unzip depL and 
      ap, al = unzip arrL 
  
  in 

(* Fonction qui supprime les parties inutiles de la protéine.
   C'est un peu subtil, parceque même un noeud sans transition, 
   ou une transition incomplète peuvent avoir des effets qu'on 
   pourrait vouloir conserver.


   On ne va ici enlever que les trucs qui ne changent rien
   à la fonction de la protéine.


  and accessiblePlaces places depL arrL = 
    let acc = Array.make (Array.length places 
*)  
object
  
  val places = places
  
  val departure_places = dp
  val departure_links = dl
  val arrival_places = ap
  val arrival_links = al

  method get_departure_places = departure_places
  method get_departure_links = departure_links
  method get_arrival_places = arrival_places
  method get_arrival_links = arrival_links

  method get_arrival_tokens (tokens : token list) : token list = 
    transition_function departure_links arrival_links tokens
  
  (* potentiel des places de départ relativement au type de la transition *)
  method launchable : bool =
    let rec aux l = 
      match l with
      | h :: t -> 
	 not places.(h)#is_empty && aux t
      | [] -> true
    in 
    (aux departure_places) && places_are_free places arrival_places
end


(*****************************************************************************************
					protéine

 réseau de Petri entier *)
and  proteine (mol : molecule) = 
  (* liste des signatures des transitions *)
  let transitions_signatures_list = build_transitions mol
    
  (* liste des signatures des places *)
  and places_signatures_list = build_nodes_list mol
    
  in


(* on crée de nouvelles places à partir de 
   la liste de types données dans la molécule
*)
  let places_list : place list = 
    List.map 
      (fun x -> new place x)
      places_signatures_list
      
  in 
  
  let (places_array : place array) = Array.of_list places_list

  in
  let (transitions_list : transition list) = 
    List.map 
      (fun x -> let s, ila, ola = x in
		new transition places_array ila ola)
      transitions_signatures_list

  in 
  
  let (transitions_array : transition array) = 
    Array.of_list transitions_list

  (* dictionnaire pour retrouver rapidement les places
     qui reçoivent des messages *)
  
  in
    

  (* fonction qui permet de créer des dictionnaires pour les 
     places qui reçoivent des messages, les places qui attrapent
     des molécules et les poignées
  *)
  
  let rec create_books 
      (places : place_type list) 
      (n : int)
      : (((string, int) BatMultiPMap.t)
	 * ((string, int) BatMultiPMap.t) 
	 * ((string, int) BatMultiPMap.t))
      =
    
    match places with
    | p :: places' ->
       let imb, mcb, hb = create_books places' (n+1) in 
       begin
	 match p with
	 | Receive_place s -> BatMultiPMap.add s n imb, mcb, hb
	 | Catch_place s -> imb, BatMultiPMap.add s n mcb, hb
	 | Handle_place s -> imb, mcb, BatMultiPMap.add s n hb
	 | _ -> imb, mcb, hb
       end
    | [] -> 
       (
	 BatMultiPMap.create String.compare (-), 
	 BatMultiPMap.create String.compare (-), 
	 BatMultiPMap.create String.compare (-)
       )
  in 

  let (input_message_book, mol_catcher_book, handle_book) = 
    create_books places_signatures_list 0
    
  in 
  
object(self) 
  val mol : molecule = mol
  val transitions = transitions_array
  val places : place array = places_array
  val mutable launchables = []
  val maps = input_message_book, mol_catcher_book, handle_book

  method get_places = places

  method get_maps = maps
    
  method init_launchables  = 
    let t_l = ref [] in 
    begin
      for i = 0 to Array.length transitions -1 do
	if transitions.(i)#launchable
	then t_l := i :: !t_l
	else ()
      done;
      launchables <- !t_l;
    end
      
      
  (* mettre à jour les transitions qui peuvent être lancées.
     Il faut prendre en compte la transition qui vient d'être lancée, 
     ainsi que les tokens qui ont pu arriver par message 

     (du coup, faire plus efficace devient un peu du bazar)
     on peut faire beaucoup plus efficace, mais pour l'instant 
     on fait au plus simple *)
  method update_launchables = self#init_launchables
    
    
  (* Lance une transition    *)
  method launch_transition (tId : transition_id) : unit = 
    let initialTokens = List.map 
      (fun x -> places.(x)#pop_token) 
      transitions.(tId)#get_departure_places
    in 
    let finalTokens = transitions.(tId)#get_arrival_tokens initialTokens
    in 
    List.map 
      (fun (x,y) -> places.(x)#set_token y)
      (zip (transitions.(tId)#get_arrival_places) finalTokens);
    ()

  (* lance une transition choisie au hasard parmi celles possibles *)
  method launch_random_transition = 
    let t = random_pick_from_list launchables in
    self#launch_transition t


  (* relaie le message aux places concernées, créant ainsi
     des tokens quand c'est possible *)
  method send_message (m : string) = 
    BatSet.PSet.map 
      (fun x -> places.(x)#add_token_from_message) 
      (BatMultiPMap.find m input_message_book)

  method set_host (h : container) : unit = 
    Array.map (fun x -> x#setHost h) places;
    ()

  method bind_mol (m : molecule) (pat : string) : bool = 
    let _,catchers,_ = maps in 
    let targets = BatMultiPMap.find pat catchers in
    let bindSiteId = Misc_library.random_pick_from_PSet targets in
    places.(bindSiteId)#add_token_from_binding m


end;;






  
