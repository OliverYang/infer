(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open Llair2TextualType

let reg_to_var_name reg = Textual.VarName.of_string (Reg.name reg)

let reg_to_annot_typ reg = to_annotated_textual_typ (Reg.typ reg)

let to_textual_loc {Loc.line; col} = Textual.Location.Known {line; col}

let translate_llair_globals globals =
  let to_textual_global global =
    let global = global.GlobalDefn.name in
    let global_name = Global.name global in
    let name = Textual.VarName.of_string global_name in
    let typ = to_textual_typ (Global.typ global) in
    Textual.Global.{name; typ; attributes= []}
  in
  let globals = StdUtils.iarray_to_list globals in
  List.map ~f:to_textual_global globals


type partial_proc_desc =
  {params: Textual.VarName.t list; locals: Textual.VarName.t list; procdecl: Textual.ProcDecl.t}

let to_qualified_proc_name func_name loc =
  let func_name = FuncName.name func_name in
  let loc = to_textual_loc loc in
  Textual.QualifiedProcName.
    {enclosing_class= TopLevel; name= Textual.ProcName.of_string ~loc func_name}


let to_result_type func_name =
  let typ = FuncName.typ func_name in
  to_annotated_textual_typ typ


let to_formals func =
  let to_textual_formal formal = reg_to_var_name formal in
  let to_textual_formal_type formal = reg_to_annot_typ formal in
  let llair_formals = StdUtils.iarray_to_list func.Llair.formals in
  let formals = List.map ~f:to_textual_formal llair_formals in
  let formals_types = List.map ~f:to_textual_formal_type llair_formals in
  (formals, formals_types)


let to_locals func =
  let to_textual_local local = reg_to_var_name local in
  let locals = Reg.Set.to_list func.Llair.locals in
  List.map ~f:to_textual_local locals


let translate_llair_functions functions =
  let function_to_formal proc_descs (func_name, func) =
    let formals, formals_types = to_formals func in
    let locals = to_locals func in
    let qualified_name = to_qualified_proc_name func_name func.Llair.loc in
    let result_type = to_result_type func_name in
    let procdecl =
      Textual.ProcDecl.
        {qualified_name; result_type; attributes= []; formals_types= Some formals_types}
    in
    {params= formals; locals; procdecl} :: proc_descs
  in
  let values = FuncName.Map.to_list functions in
  List.fold values ~f:function_to_formal ~init:[]


let translate sourcefile (llair_program : Llair.Program.t) : Textual.Module.t =
  let globals = translate_llair_globals llair_program.Llair.globals in
  (* We'll build the procdesc partially until we have all the pieces required in Textual
     and can add them to the list of declarations *)
  let partial_procs = translate_llair_functions llair_program.Llair.functions in
  let proc_decls = List.map ~f:(fun {procdecl} -> Textual.Module.Procdecl procdecl) partial_procs in
  let globals = List.map ~f:(fun global -> Textual.Module.Global global) globals in
  let structs =
    List.map
      ~f:(fun (_, struct_) -> Textual.Module.Struct struct_)
      (Textual.TypeName.Map.bindings !Llair2TextualType.structMap)
  in
  let decls = List.append proc_decls globals in
  let decls = List.append decls structs in
  Textual.Module.{attrs= []; decls; sourcefile}
