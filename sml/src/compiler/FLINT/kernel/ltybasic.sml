(* Copyright (c) 1997 YALE FLINT PROJECT *)
(* ltybasic.sml *)

structure LtyBasic : LTYBASIC = 
struct

local structure PT = PrimTyc
      structure DI = DebIndex
      structure LK = LtyKernel

      fun bug msg = ErrorMsg.impossible("LtyExtern: "^msg)
      val say = Control.Print.say

      (** common utility functions *)
      val tk_inj = LK.tk_inj
      val tk_out = LK.tk_out

      val tc_inj = LK.tc_inj
      val tc_out = LK.tc_out 
 
      val lt_inj = LK.lt_inj
      val lt_out = LK.lt_out 

      val tcc_env = LK.tcc_env
      val ltc_env = LK.ltc_env
      val tc_whnm = LK.tc_whnm
      val lt_whnm = LK.lt_whnm
      val tc_norm = LK.tc_norm
      val lt_norm = LK.lt_norm

      val itos = Int.toString
      fun plist(p, []) = ""
        | plist(p, x::xs) = 
            (p x) ^ (String.concat (map (fn z => ("," ^ (p z))) xs))

      fun parw(p, (t1, t2)) = "<" ^ (p t1) ^ "> -> <" ^ (p t2) ^ ">"
in

open LtyDef

(** new a type variable, currently not used *)
val mkTvar : unit -> tvar = LK.mkTvar

(** utility functions for constructing tkinds *)
fun tkc_arg n = 
  let fun h (n, r) = if n < 1 then r else h(n-1, tkc_mono::r)
   in h(n, [])
  end

val tkc_fn1 = tkc_fun(tkc_seq(tkc_arg 1), tkc_mono)
val tkc_fn2 = tkc_fun(tkc_seq(tkc_arg 2), tkc_mono)
val tkc_fn3 = tkc_fun(tkc_seq(tkc_arg 3), tkc_mono)

fun tkc_int 0 = tkc_mono
  | tkc_int 1 = tkc_fn1
  | tkc_int 2 = tkc_fn2
  | tkc_int 3 = tkc_fn3
  | tkc_int i = tkc_fun(tkc_seq(tkc_arg i), tkc_mono)

(** utility functions for constructing tycs *)
val tcc_int    = tcc_prim PT.ptc_int31
val tcc_int32  = tcc_prim PT.ptc_int32
val tcc_real   = tcc_prim PT.ptc_real
val tcc_string = tcc_prim PT.ptc_string
val tcc_exn    = tcc_prim PT.ptc_exn
val tcc_void   = tcc_prim PT.ptc_void
val tcc_unit   = tcc_tuple []
val tcc_bool   = 
  let val tbool = tcc_sum [tcc_unit, tcc_unit]
      val tsig_bool = tcc_fn ([tkc_mono], tbool)
   in tcc_fix((1, tsig_bool, []), 0)
  end

val tcc_list   =  (* not exported, used for the printing purpose *)
  let val alpha = tcc_var (DI.innermost, 0)
      val tlist = tcc_var (DI.innersnd, 0)
      val alist = tcc_app (tlist, [alpha])
      val tcc_cons = tcc_tuple [alpha, alist]
      val tlist = tcc_fn([tkc_mono], tcc_sum [tcc_cons, tcc_unit])
                            (** the order here should be consistent with
                                that in basics/basictypes.sml **)
      val tsig_list = tcc_fn([tkc_int 1], tlist)
   in tcc_fix((1, tsig_list, []), 0)
  end

fun tcc_tv i     = tcc_var(DI.innermost, i)
fun tcc_ref x    = tcc_app(tcc_prim PT.ptc_ref, [x])
fun tcc_array x  = tcc_app(tcc_prim PT.ptc_array, [x])
fun tcc_vector x = tcc_app(tcc_prim PT.ptc_vector, [x])
fun tcc_etag x   = tcc_app(tcc_prim PT.ptc_etag, [x])

(** primitive lambda ltys *)
val ltc_int    = ltc_tyc tcc_int
val ltc_int32  = ltc_tyc tcc_int32
val ltc_real   = ltc_tyc tcc_real
val ltc_string = ltc_tyc tcc_string
val ltc_exn    = ltc_tyc tcc_exn
val ltc_void   = ltc_tyc tcc_void
val ltc_unit   = ltc_tyc tcc_unit
val ltc_bool   = ltc_tyc tcc_bool

val ltc_tv     = ltc_tyc o tcc_tv
val ltc_ref    = ltc_tyc o tcc_ref o ltd_tyc
val ltc_array  = ltc_tyc o tcc_array o ltd_tyc
val ltc_vector = ltc_tyc o tcc_vector o ltd_tyc
val ltc_etag   = ltc_tyc o tcc_etag o ltd_tyc

val ltc_top = ltc_ppoly([tkc_mono], ltc_tv 0)

(***************************************************************************
 *            UTILITY FUNCTIONS FOR TESTING EQUIVALENCE                    *
 ***************************************************************************)

(** testing equivalence of tkinds, tycs, and ltys *)
val tk_eqv    : tkind * tkind -> bool = LK.tk_eqv
val tc_eqv    : tyc * tyc -> bool = LK.tc_eqv
val lt_eqv    : lty * lty -> bool = LK.lt_eqv

(** testing the equivalence for tycs and ltys with relaxed constraints *)
val tc_eqv_bx : tyc * tyc -> bool = LK.tc_eqv_bx
val lt_eqv_bx : lty * lty -> bool = LK.lt_eqv_bx

(***************************************************************************
 *            UTILITY FUNCTIONS FOR PRETTY PRINTING                        *
 ***************************************************************************)

(** pretty printing of tkinds, tycs, and ltys *)
fun tk_print (x : tkind) = 
  let fun g (LK.TK_MONO) = "K0"
        | g (LK.TK_BOX) = "KB0"
        | g (LK.TK_FUN z) =  (parw(tk_print, z))
        | g (LK.TK_SEQ zs) = "KS(" ^ (plist(tk_print, zs)) ^ ")"
   in g (tk_out x)
  end

fun tc_print (x : tyc) =
  let fun g (LK.TC_VAR(i,j)) = "TV(" ^ (DI.di_print i) ^ "," ^ (itos j) ^ ")"
        | g (LK.TC_NVAR(v,d,i)) = "NTV(v" ^ (itos v) ^ "," ^ (itos d) 
                               ^ "," ^ (itos i) ^ ")"
        | g (LK.TC_PRIM pt) = PT.pt_print pt
        | g (LK.TC_FN([], t)) = "TF(0," ^ (tc_print t) ^ ")"
        | g (LK.TC_FN(ks, t)) = 
              "\\" ^ (itos (length ks)) ^ ".(" ^ (tc_print t) ^ ")"
        | g (LK.TC_APP(t, [])) = tc_print t ^ "[]"
        | g (LK.TC_APP(t, zs)) =
              (tc_print t) ^ "[" ^ (plist(tc_print, zs)) ^ "]"
        | g (LK.TC_SEQ zs) = "TS(" ^ (plist(tc_print,zs)) ^ ")"
        | g (LK.TC_PROJ (t, i)) = 
              "TP(" ^ (tc_print t) ^ "," ^ (itos i) ^ ")"
        | g (LK.TC_SUM tcs) =  
              "TSUM(" ^ (plist(tc_print, tcs)) ^ ")"
        | g (LK.TC_FIX ((_, tc, ts), i)) = 
              if tc_eqv(x,tcc_bool) then "B" 
              else if tc_eqv(x,tcc_list) then "LST" 
                   else (let val ntc = case ts of [] => tc
                                                | _ => tcc_app(tc, ts)
                          in ("DT{" ^ (tc_print ntc) ^ "===" ^ (itos i) ^ "}")
                         end)
        | g (LK.TC_ABS t) = "Ax(" ^ (tc_print t) ^ ")"
        | g (LK.TC_BOX t) = "Bx(" ^ (tc_print t) ^ ")"
        | g (LK.TC_TUPLE zs) = "TT<" ^ (plist(tc_print, zs)) ^ ">"
        | g (LK.TC_ARROW (_,z1,z2)) = parw(fn u => plist(tc_print,u), (z1,z2))
        | g (LK.TC_PARROW _) = bug "unexpected TC_PARROW in tc_print"
        | g (LK.TC_CONT ts) = "Cnt(" ^ (plist(tc_print,ts)) ^ ")"
        | g (LK.TC_IND _) = bug "unexpected TC_IND in tc_print"
        | g (LK.TC_ENV _) = bug "unexpected TC_ENV in tc_print"
   in g (tc_out x)
  end (* function tc_print *)

fun lt_print (x : lty) =
  let fun h (i, t) = "(" ^ (itos i) ^ "," ^ (lt_print t) ^ ")"

      fun g (LK.LT_TYC t) = tc_print t
        | g (LK.LT_STR zs) = "S{" ^ (plist(lt_print, zs)) ^ "}"
        | g (LK.LT_PST zs) = "PS{" ^ (plist(h, zs)) ^ "}"
        | g (LK.LT_FCT (ts1,ts2)) = 
             "(" ^ (plist(lt_print, ts1)) ^ ") ==> ("
                 ^ (plist(lt_print, ts2)) ^ ")"
        | g (LK.LT_POLY(ks, ts)) = 
             "Q" ^ (itos (length ks)) ^ ".(" ^ (plist(lt_print,ts)) ^ ")"
        | g (LK.LT_CONT ts) = "CNT(" ^ (plist(lt_print, ts)) ^ ")"
        | g (LK.LT_IND _) = bug "unexpected LT_IND in lt_print"
        | g (LK.LT_ENV _) = bug "unexpected LT_ENV in lt_print"

   in g (lt_out x)
  end (* function lt_print *)

(** finding out the depth for a tyc's innermost-bound free variables *)
val tc_depth : tyc * depth -> depth = LK.tc_depth
val tcs_depth: tyc list * depth -> depth = LK.tcs_depth

(** adjusting an lty or tyc from one depth to another *)
fun lt_adj (lt, d, nd) = 
  if d = nd then lt else lt_norm(ltc_env(lt, 0, nd - d, LK.initTycEnv))

fun tc_adj (tc, d, nd) = 
  if d = nd then tc else tc_norm(tcc_env(tc, 0, nd - d, LK.initTycEnv))

(** the following function is called only inside transtype.sml *)
fun tc_adj_one (tc, d, nd) = 
  if d = nd then tc 
  else (let val dd = nd - d
         in tc_norm(tcc_env(tc, 1, dd + 1, 
                            LK.tcInsert(LK.initTycEnv, (NONE, dd))))
        end)

(** automatically flattening the argument or the result type *)
val lt_autoflat : lty -> bool * lty list * bool = LK.lt_autoflat

(***************************************************************************
 *            UTILITY FUNCTIONS ON TKIND ENVIRONMENT                       *
 ***************************************************************************)

(** tkind environment: maps each tyvar, i.e., its debindex, to its kind *)
type tkindEnv = tkind list list

(** utility functions for manipulating the tkindEnv *)
exception tkUnbound
val initTkEnv : tkindEnv = []

fun tkLookup (kenv, i, j) = 
  let val ks = List.nth(kenv, i-1) handle _ => raise tkUnbound
   in List.nth(ks, j) handle _ => raise tkUnbound
  end

fun tkInsert (kenv, ks) = ks::kenv

(***************************************************************************
 *            UTILITY FUNCTIONS ON TYC ENVIRONMENT                         *
 ***************************************************************************)

exception tcUnbound = LK.tcUnbound
type tycEnv = LK.tycEnv
val initTycEnv = LK.initTycEnv
val tcInsert = LK.tcInsert

(***************************************************************************
 *            UTILITY FUNCTIONS ON LTY ENVIRONMENT                         *
 ***************************************************************************)

(** utility values and functions on ltyEnv *)
type ltyEnv = (lty * DebIndex.depth) IntmapF.intmap

exception ltUnbound
val initLtyEnv : ltyEnv = IntmapF.empty

fun ltLookup (venv, lv, nd) = 
  let val (lt, d) = (IntmapF.lookup venv lv) handle _ => 
                        (say "**** hmmm, I didn't find the variable ";
                         say (Int.toString lv); say "\n";
                         raise ltUnbound)
   in if d=nd then lt
      else if d > nd then bug "unexpected depth info in ltLookup"
           else ltc_env(lt, 0, nd - d, LK.initTycEnv)
  end

fun ltInsert (venv, lv, lt, d) = IntmapF.add(venv, lv, (lt, d))

end (* top-level local *)
end (* structure LtyBasic *)

