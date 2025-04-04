(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
module F = Format

[@@@warning "-32-60"]

type unsat_info = {reason: unit -> string; source: string * int * int * int}

type 'a t = Unsat of unsat_info | Sat of 'a [@@deriving equal]

(** for [open]ing to get [Sat] and [Unsat] in the namespace *)
module Types : sig
  type nonrec unsat_info = unsat_info = {reason: unit -> string; source: string * int * int * int}

  type 'a sat_unsat_t = 'a t = Unsat of unsat_info | Sat of 'a [@@deriving equal]
end

val pp_unsat_info : F.formatter -> unsat_info -> unit

val log_unsat : unsat_info -> unit

val pp : (F.formatter -> 'a -> unit) -> F.formatter -> 'a t -> unit

val map : ('a -> 'b) -> 'a t -> 'b t

val bind : ('a -> 'b t) -> 'a t -> 'b t

val sat : 'a t -> 'a option

val of_option : unsat_info -> 'a option -> 'a t

val list_fold : 'a list -> init:'accum -> f:('accum -> 'a -> 'accum t) -> 'accum t

val to_list : 'a t -> 'a list

val filter : 'a t list -> 'a list
(** keep only [Sat _] elements *)

val seq_fold : 'a Stdlib.Seq.t -> init:'accum -> f:('accum -> 'a -> 'accum t) -> 'accum t

module Import : sig
  include module type of Types

  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t

  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
end

val log_source_info : bool ref
[@@warning "-unused-value-declaration"]
(** whether to print the (infer) source location on [Unsat]; set to [false] in unit tests *)
