(******************************************************************************)
(*                                                                            *)
(*                               PROJECT HELM                                 *)
(*                                                                            *)
(*                     A tactic to print Coq objects in XML                   *)
(*                                                                            *)
(*                Claudio Sacerdoti Coen <sacerdot@cs.unibo.it>               *)
(*                                 02/12/1999                                 *)
(*                                                                            *)
(* This module compute the list of variables occurring in a term from the     *)
(* term and the list of variables possibly occuring in it                     *)
(*                                                                            *)
(******************************************************************************)

let get_depth_of_var vl v =
 let rec aux n =
  function
     [] -> None
   | (he::tl) -> if List.mem v he then Some n else aux (n + 1) tl
 in
  aux 0 vl
;;

exception CookingInternalError;;

let string_of_vars_list =
 let add_prefix n s = string_of_int n ^ ": " ^ s in
 let rec aux =
  function
     [n,v] -> (n,v)
   | (n,v)::tl ->
      let (k,s) = aux tl in
       if k = n then (k, v ^ " " ^ s) else (n, v ^ " " ^ add_prefix k s)
   | [] -> raise CookingInternalError
 in
  function
     [] -> ""
   | vl -> let (k,s) = aux vl in add_prefix k s
;;

(*CSC commento sbagliato ed obsoleto *)
(* If t is \v1. ... \vn.t' where v1, ..., vn are in the variable list vl then *)
(* get_params_from_type vl t returns [v1; ...; vn]                            *)
let get_params_from_type vl t =
 let rec rget t l =
  let module T = Term in
  let module N = Names in
   match T.kind_of_term t with
      T.IsProd (N.Name id, _, target) ->
       let id' = N.string_of_id id in
        (match get_depth_of_var vl id' with
            None   -> l
          | Some n -> rget target ((n,id')::l)
        )
    | T.IsCast (term, _) -> rget term l
    | _ -> l
 in
  let pl = List.rev (rget t []) in
   string_of_vars_list pl
;;

(* add_cooking_information csp vl                               *)
(*  when  csp is the section path of the most cooked object co  *)
(*  and   vl  is the list of variables possibly occuring in co  *)
(* returns the list of variables actually occurring in co       *)
let add_cooking_information sp vl =
 let module D = Declarations in
 let module G = Global in
 let module N = Names in
 let module T = Term in
 let module X = Xml in
  try
   let {D.const_body=val0 ; D.const_type = typ} = G.lookup_constant sp in
   let typ = T.body_of_type typ in
    get_params_from_type vl typ
  with
   Not_found ->
    try
     let {D.mind_packets=packs ; D.mind_nparams=nparams} =
      G.lookup_mind sp
     in
      let {D.mind_nf_arity=arity} = packs.(0) in
      let arity = T.body_of_type arity in
       get_params_from_type vl arity
    with
     Not_found -> Util.anomaly "Cooking of an uncoockable term required"
;;
