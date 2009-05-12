(** Visitor for BAP AST

    The design of this visitor was highly influenced by the one from CIL.
 *)

open Type
open Ast



class type t = object
  (** Called when visiting an expression *)
  method visit_exp: exp -> exp visit_action

  (** Called when visiting a statement *)
  method visit_stmt : stmt -> stmt visit_action

  (** Called when visiting a referenced variable *)
  method visit_rvar : var -> var visit_action

  (** Called when visiting assigned variable.
      Note that in a Move(), referenced variables will be visited first, so
      that this can be used to add the assigned variable to your context.
  *)
  method visit_avar : var -> var visit_action

  (** Called on the binding when recursinig into a Let. This allows
      doing stuff between the first and second expressions in a Let. *)
  method visit_binding: var * exp -> (var * exp) visit_action 

end

class nop : t = object
  method visit_exp _   = `DoChildren
  method visit_stmt _  = `DoChildren
  method visit_avar _  = `DoChildren
  method visit_rvar _  = `DoChildren
  method visit_binding _ = `DoChildren
end


let rec action vischil startvisit node=
  match startvisit node with
  | `SkipChildren -> node
  | `ChangeTo x -> x (* FIXME: warn if x = node *)
  | `DoChildren -> vischil node

(* this really should be a more shallow comparison, otherwise it will
   be slow when there is a deeply nested change *)
let wrap f v = let v' = f v in if v = v' then v else v'

let rec exp_accept visitor = 
  let vischil = function
    | Int _ as i -> i
    | Lab _ as l -> l
    | Var v ->
	Var(rvar_accept visitor v)
    | BinOp(bop, v1, v2) -> 
	let v1' = exp_accept visitor v1 in 
	let v2' = exp_accept visitor v2 in 
	BinOp(bop, v1', v2')
    | UnOp(up, v) -> 
	let v' = exp_accept visitor v in 
	UnOp(up, v')
    | Cast(ct, t, v) ->
	let v' = exp_accept visitor v in 
	Cast(ct,t,v')
    | Unknown _ as exp -> exp
    | Load(v1,v2,v3, t) -> 
	let v1' = exp_accept visitor v1 in 
	let v2' = exp_accept visitor v2 in 
	let v3' = exp_accept visitor v3 in 
	Load(v1',v2',v3', t)
    | Store(v1,v2,v3,v4, t) ->
	let v1' = exp_accept visitor v1 in 
	let v2' = exp_accept visitor v2 in 
	let v3' = exp_accept visitor v3 in 
	let v4' = exp_accept visitor v4 in 
	Store(v1',v2',v3',v4',t)
    | Let(v,e1,e2) ->
	let (v',e1') = binding_accept visitor (v,e1) in
	let e2' = exp_accept visitor e2 in
	Let(v', e1', e2')
  in
  action (wrap vischil) visitor#visit_exp


and avar_accept visitor =
  action Util.id visitor#visit_avar
and rvar_accept visitor = 
  action Util.id visitor#visit_rvar

and binding_accept visitor =
  let vischil (v,e) =
    let v' = avar_accept visitor v in
    let e' = exp_accept visitor e in
    (v', e')
  in
  action vischil visitor#visit_binding
