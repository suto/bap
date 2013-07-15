(** General disassembly stuff *)

(* open Asmir *)
open Type
exception Unimplemented

let arch_to_x86_mode = function
  | X86_32 -> Disasm_i386.X86
  | X86_64 -> Disasm_i386.X8664

let disasm_instr arch = Disasm_i386.disasm_instr (arch_to_x86_mode arch)

let is_temp = Var_temp.is_temp

let is_decode_error = function
  | Ast.Special(s, _) when BatString.starts_with s "Unknown instruction" -> true
  | _ -> false
