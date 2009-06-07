(* COPYRIGHT (c) 1998 YALE FLINT PROJECT *)
(* transtypes.sml *)

signature TRANSTYPES = 
sig

  type primaryEnv = Modules.primary list list
  datatype argtyc 
    = TYCarg of Types.tycon
    | FCTarg of Modules.fctEntity
		
  (* val tpsKnd : tycpath -> PLambdaType.tkind, *)
  val primaryToTyc : primaryEnv -> argtyc -> PLambdaType.tyc,
 
  val tyconToTyc : Types.tycon * primaryEnv * int -> PlambdaType.tyc
  val toTyc  : primaryEnv -> DebIndex.depth -> Types.ty -> PLambdaType.tyc
  val toLty  : primaryEnv -> DebIndex.depth -> Types.ty -> PLambdaType.lty
  val strLty : Modules.Structure * primaryEnv * DebIndex.depth 
               * ElabUtil.compInfo -> PLambdaType.lty
  val fctLty : Modules.Functor * primaryEnv * DebIndex.depth 
               * ElabUtil.compInfo -> PLambdaType.lty}

end (* signature TRANSTYPES *)

structure TransTypes : TRANSTYPES = 
struct
local structure T = Types
      structure BT = BasicTypes
      structure DA = Access   
      structure DI = DebIndex
      structure EE = EntityEnv
      structure EM = ErrorMsg
      structure EPC = EntPathContext
      structure EV = EvalEntity
      structure INS = Instantiate
      structure IP = InvPath
      structure LT = PLambdaType
      structure PT = PrimTyc
      structure MU = ModuleUtil
      structure SE = StaticEnv
      structure TU = TypesUtil
      structure PP = PrettyPrintNew
      structure TP = TycPath
      structure FTM = FlexTycMap

      open Types Modules ElabDebug
in

type primaryEnv = Modules.primary list list
(* we may not need the sig and entpath parts. stamp list list may suffice
 * for the translation from primaries to db indexes *)

datatype argtyc 
  = TYCarg of Types.tycon
  | FCTarg of Modules.fctEntity

(*
type primaryEnv = (Types.tycon list 
		   * ((Stamps.stamp * Modules.fctSig) list)) list
*)
(* this is superceded by datatype primary in Instantiate *)
(* datatype primary = FormalTyc of Types.tycon
		 | FormalFct of Stamps.stamp * fctSig
*)

fun bug msg = ErrorMsg.impossible ("TransTypes: " ^ msg)
val say = Control.Print.say 
val debugging = (* FLINT_Control.tmdebugging *) ref true
fun debugmsg (msg: string) =
  if !debugging then (say msg; say "\n") else ()
val debugPrint = (fn x => debugPrint debugging x)
val defaultError =
  EM.errorNoFile(EM.defaultConsumer(),ref false) SourceMap.nullRegion

val env = StaticEnv.empty

fun ppType x = 
 ((PP.with_pp (EM.defaultConsumer())
           (fn ppstrm => (PP.string ppstrm "find: ";
                          PPType.resetPPType();
                          PPType.ppType env ppstrm x)))
  handle _ => say "fail to print anything")

fun ppTycon x = 
    ((PP.with_pp (EM.defaultConsumer())
        (fn ppstrm => (PP.string ppstrm "find: ";
                       PPType.resetPPType();
                       PPType.ppTycon env ppstrm x)))
    handle _ => say "fail to print anything")


fun ppLtyc ltyc = 
    PP.with_default_pp (fn ppstrm => PPLty.ppTyc 20 ppstrm ltyc)


(****************************************************************************
 *               TRANSLATING ML TYPES INTO FLINT TYPES                      *
 ****************************************************************************)
local val recTyContext = ref [~1]
in 
fun enterRecTy (a) = (recTyContext := (a::(!recTyContext)))
fun exitRecTy () = (recTyContext := tl (!recTyContext))
fun recTyc (i) = 
      let val x = hd(!recTyContext)
          val base = DI.innermost   (* = 1 *)
       in if x = 0 then LT.tcc_var(base, i)
          else if x > 0 then LT.tcc_var(DI.di_inner base(* 2 *), i)   
               else bug "unexpected RECtyc"
      end
fun freeTyc (i) = 
      let val x = hd(!recTyContext)
          val base = DI.di_inner (DI.innermost)  (* = 2 *)
       in if x = 0 then LT.tcc_var(base, i)
          else if x > 0 then LT.tcc_var(DI.di_inner base(* 3 *), i)
               else bug "unexpected RECtyc"
      end
end (* end of recTyc and freeTyc hack *)



(* 
(* translating tycpaths to tkinds *)
fun tpsKnd (TP.TP_VAR{kind,...}) = kind 
  | tpsKnd (TP.TP_FCT(argtps, bodytps)) = 
      LT.tkc_fun(map tpsKnd argtps, LT.tkc_seq (map tpsKnd bodytps))
  | tpsKnd (TP.TP_SEL(TP.TP_APP(TP.TP_VAR{kind,...}, paramtps), i)) =
      let val (_, result) = LT.tkd_fun kind
	  val seq = LT.tkd_seq result
	  val _ = debugmsg ("--tpsKnd fct result list length "^
			    Int.toString (length seq)^" selecting "^
			    Int.toString i) 
	  val knd = List.nth(seq, i) 
	      handle General.Subscript => 
		     bug ("Unexpected functor result length, selecting "
			  ^Int.toString i^" in length "
			  ^Int.toString(length seq)^" seq")
					    
      in knd
      end
  | tpsKnd _ = bug "unexpected tycpath parameters in tpsKnd"

(* translating tycpath to LT.tyc -- *)
fun tpsTyc (penv : flexmap) d tp = 
  let fun h (TP.TP_VAR {tdepth, num, ...}, cur) =
            let val finaldepth = DI.relativeDepth(cur, tdepth)
		val _ = debugmsg ("--tpsTyc: producing tcc_var "^
				DI.dp_print tdepth^" "
			   ^Int.toString num^" current depth "^DI.dp_print cur)
	    in
		if finaldepth < 0 then bug "Invalid depth calculation"
		else LT.tcc_var(finaldepth, num)
	    end
        | h (TP.TP_TYC tc, cur) = tyconToTyc(penv, tc, cur)
        | h (TP.TP_SEL (tp, i), cur) = LT.tcc_proj(h(tp, cur), i)
        | h (TP.TP_APP (tp, ps), cur) = 
              LT.tcc_app(h(tp, cur), map (fn x => h(x, cur)) ps)
        | h (TP.TP_FCT (ps, ts), cur) = 
             let val _ = debugmsg ">>tpsTyc[TP_FCT]"
		 val ks = map tpsKnd ps
                 val cur' = DI.next cur
                 val ts' = map (fn x => h(x, cur')) ts
		 val _ = debugmsg "<<tpsTyc[TP_FCT]"
             in LT.tcc_fn(ks, LT.tcc_seq ts')
             end

   in h(tp, d)
  end
*)

(* based on tpsTyc *)
fun primaryToTyc (primary: argtyc), penv : primaryEnv, depth: int) =
    case primary 
     of TYCarg tycon => tyconToTyc(tycon,penv,depth)
      | FCTarg fctEnt => bug "Unimplemented"

(*
and tyconToTyc = 
  Stats.doPhase(Stats.makePhase "Compiler 043 1-tyconToTyc") tyconToTyc x
*)

(* translate Types.tycon to LT.tyc *)
and tyconToTyc(tc : Types.tycon, penv : primaryEnv, d: int) =
    let fun dtsTyc nd ({dcons: dconDesc list, arity, ...} : dtmember) = 
	    let val nnd = if arity=0 then nd else nd+1
		fun f ({domain=NONE, rep, name}, r) = (LT.tcc_unit)::r
		  | f ({domain=SOME t, rep, name}, r) = 
		    (toTyc penv nnd t)::r

		val _ = enterRecTy arity
		val core = LT.tcc_sum(foldr f [] dcons)
		val _ = exitRecTy()

		val resTyc = if arity=0 then core
			     else (let val ks = LT.tkc_arg arity
				    in LT.tcc_fn(ks, core)
				   end)
	     in (LT.tkc_int arity, resTyc)
	    end

	fun dtsFam (freetycs, fam as { members, ... } : dtypeFamily) =
	    case ModulePropLists.dtfLtyc fam of
	      of SOME (tc, od) =>
		 LT.tc_adj(tc, od, d) (* INVARIANT: tc contains no free variables 
				       * so tc_adj should have no effects *)
	       | NONE =>
		 let fun ttk (GENtyc{ arity, ...}) = LT.tkc_int arity
		       | ttk (DEFtyc{tyfun=TYFUN{arity, ...},...}) =
			 LT.tkc_int arity
		       | ttk _ = bug "unexpected ttk in dtsFam"
		     val ks = map ttk freetycs
		     val (nd, hdr) = 
			 case ks
			  of [] => (d, fn t => t)
			   | _ => (DI.next d, fn t => LT.tcc_fn(ks, t))
		     val mbs = Vector.foldr (op ::) nil members
		     val mtcs = map (dtsTyc (DI.next nd)) mbs
		     val (fks, fts) = ListPair.unzip mtcs
		     val nft = case fts of [x] => x | _ => LT.tcc_seq fts
		     val tc = hdr(LT.tcc_fn(fks, nft)) 
		     val _ = ModulePropLists.setDtfLtyc (fam, SOME(tc, d))
		  in tc
		 end

	fun gentyc (_, PRIMITIVE pt) = LT.tcc_prim (PrimTyc.pt_fromint pt)
	  | gentyc (stmp, DATATYPE {index, family, freetycs, stamps, root}) = 
	    if ST.eq(stmp, TU.tycStamp(BT.refTycon)) then LT.tcc_prim(PT.ptc_ref) else
	      let val tc = dtsFam (freetycs, family)
		  val n = Vector.length stamps 
		  val names = Vector.map (fn ({tycname,...}: dtmember) => 
					     Symbol.name tycname)
					 (#members family)
		  (* invariant: n should be the number of family members *)
	       in LT.tcc_fix((n, names, tc, (map g freetycs)), index)
	      end
	  | gentyc (_, ABSTRACT tc) = (toTyc tc)
	  | gentyc (stmp, FORMAL) = 
	      let fun findindex (((_,s1,_)::rest)::penv, index, num) =
		      if Stamps.eq(s1,stmp) then (index, num)
		      else findindex (rest::penv, index, num + 1)
		    | findindex ([]::penv, index, num) = 
		      findindex(penv, index + 1, 0)
		    | findindex ([],_,_) = 
		      bug "formal tycon not bound in primary environment"
		  val (dbIndex, num) = findindex(penv, 1, 0)
	       in LT.tcc_var(dbIndex, num)
	      end
	  | gentyc (_, TEMP) = bug "unexpected TEMP kind in tyconToTyc-h"

	and toTyc (tycon as GENtyc {stamp, arity, kind, ...}) =
	      gentyc(stamp, kind)
	  | toTyc (DEFtyc{tyfun, ...}) = tfTyc(penv, tyfun, d)
	  | toTyc (RECtyc i) = recTyc i
	  | toTyc (FREEtyc i) = freeTyc i
	  | toTyc (PATHtyc{arity, path=InvPath.IPATH ss, entPath}) = (* bug? *)
 	    ((* say "*** Warning for compiler writers: PATHtyc ";
	      app (fn x => (say (Symbol.name x); say ".")) ss;
	      say " in translate: ";
	      say (EntPath.entPathToString entPath);
	      say "\n"; *)
	     if arity > 0 then LT.tcc_fn(LT.tkc_arg arity, LT.tcc_void)
	     else LT.tcc_void)
	  | toTyc (RECORDtyc _) = bug "unexpected RECORDtyc in tyconToTyc-g"
	  | toTyc (ERRORtyc) = bug "unexpected tycon in tyconToTyc-g"
     in toTyc tc
    end (* fun tyconToTyc *)

and tfTyc (penv : primaryEnv, TYFUN{arity=0, body}, d) = toTyc penv d body
  | tfTyc (penv, TYFUN{arity, body}, d) = 
      let val ks = LT.tkc_arg arity
       in LT.tcc_fn(ks, toTyc penv (DI.next d) body)
      end

(* translating Types.ty to LT.tyc *)
and toTyc (penv : primaryEnv) d t = 
  let val m : (tyvar * LT.tyc) list ref = ref []
      fun lookTv tv = 
        let val xxx = !m
            fun uu ((z as (a,x))::r, b, n) = 
                 if a = tv then (x, z::((rev b)@r)) else uu(r, z::b, n+1)
              | uu ([], b, n) = let val zz = h (!tv)
                                    val nb = if n > 64 then tl b else b
                                 in (zz, (tv, zz)::(rev b))
                                end
            val (res, nxx) = uu(xxx, [], 0)
         in m := nxx; res
        end

      and h (INSTANTIATED t) = g t
        | h (LBOUND(SOME{depth,index,...})) =
             LT.tcc_var(DI.relativeDepth(d, depth), index)
        | h (UBOUND _) = LT.tcc_void
            (* DBM: should this have been converted to an LBOUND before
             * being passed to toTyc? 
	     * GK: Doesn't seem to experimentally *)
            (* dbm: a user-bound type variable that didn't get generalized;
               treat the same as an uninstantiated unification variable. 
	       E.g. val x = ([]: 'a list; 1) *)
        | h (OPEN _) = LT.tcc_void
            (* dbm: a unification variable that was neither instantiated nor
	       generalized.  E.g. val x = ([],1); -- the unification variable
               introduced by the generic instantiation of the type of [] is
               neither instantiated nor generalized. *)
        | h _ = bug "toTyc:h" (* LITERAL and SCHEME should not occur *)

      and g (VARty tv) = lookTv tv
	| g (CONty(RECORDtyc _, [])) = LT.tcc_unit
        | g (CONty(RECORDtyc _, ts)) = LT.tcc_tuple (map g ts)
        | g (CONty(tyc, [])) = (debugmsg "--toTyc[CONty[]]"; 
				tyconToTyc(tyc, penv, d))
        | g (CONty(DEFtyc{tyfun,...}, args)) = 
	  (debugmsg "--toTyc[CONty[DEFtyc]"; g(TU.applyTyfun(tyfun, args)))
	| g (CONty (tc as GENtyc { kind, ... }, ts)) =
	  (case (kind, ts) of
	       (ABSTRACT _, ts) =>
	       (debugmsg "--toTyc[CONty[ABSTRACT]]";
		LT.tcc_app(tyconToTyc(tc, penv, d), map g ts))
             | (_, [t1, t2]) =>
               if TU.eqTycon(tc, BT.arrowTycon) 
	       then LT.tcc_parrow(g t1, g t2)
               else LT.tcc_app(tyconToTyc(tc, penv, d), [g t1, g t2])
	     | _ => LT.tcc_app (tyconToTyc (tc, penv, d), map g ts))
        | g (CONty(tc, ts)) = LT.tcc_app(tyconToTyc(tc, penv, d), map g ts)
        | g (IBOUND i) = LT.tcc_var(DI.innermost, i) 
			 (* [KM] IBOUNDs are encountered when toTyc
                          * is called on the body of a POLYty in 
                          * toLty (see below). *)
	| g (MARKty (t, _)) = g t
        | g (POLYty _) = bug "unexpected poly-type in toTyc"
	| g (UNDEFty) = 
          (* mkVB kluge!!! *) LT.tcc_void
	  (* bug "unexpected undef-type in toTyc" *)
        | g (WILDCARDty) = bug "unexpected wildcard-type in toTyc"      

   in g t 
  end (* toTyc *)

(* translating polytypes *)
and toLty (penv : primaryEnv) d (POLYty {tyfun=TYFUN{arity=0, body}, ...}) = 
    toLty (penv : primaryEnv) d body
  | toLty (penv : primaryEnv) d (POLYty {tyfun=TYFUN{arity, body},...}) = 
      let val ks = LT.tkc_arg arity
       in LT.ltc_poly(ks, [toLty penv (DI.next d) body])
      end
  | toLty (penv : primaryEnv) d  x = LT.ltc_tyc (toTyc penv d x) 


(****************************************************************************
 *               TRANSLATING ML MODULES INTO FLINT TYPES                    *
 ****************************************************************************)

fun specLty (elements : (Symbol.symbol * spec) list, entEnv, 
	     penv : primaryEnv, depth, compInfo) = 
  let val _ = debugmsg ">>specLty"
      fun g ([], entEnv, ltys) = rev ltys
        | g ((sym, (TYCspec _ ))::rest, entEnv, ltys) =
              (debugmsg ("--specLty[TYCspec] "^Symbol.name sym); 
	       g(rest, entEnv, ltys))
        | g ((sym, STRspec {sign, entVar, ...})::rest, entEnv, ltys) =
              let val rlzn = EE.lookStrEnt(entEnv,entVar)
                  val _ = debugmsg ("--specLty[STRspec] "^Symbol.name sym)
		  val lt = strRlznLty(penv, sign, rlzn, depth, compInfo) 
               in g(rest, entEnv, lt::ltys)
              end
        | g ((sym, FCTspec {sign, entVar, ...})::rest, entEnv, ltys) = 
              let val rlzn = EE.lookFctEnt(entEnv,entVar)
                  val _ = debugmsg ("--specLty[FCTspec] "^Symbol.name sym)
		  val lt = fctRlznLty(penv, sign, rlzn, depth, compInfo) 
               in g(rest, entEnv, lt::ltys)
              end
        | g ((sym, spec)::rest, entEnv, ltys) =
              let val _ = debugmsg ("--specLtyElt "^Symbol.name sym)
                  (* TODO translate entEnv results here? *)
		  fun transty ty = 
                    ((MU.transType entEnv ty)
                      handle EE.Unbound =>
                         (debugmsg "$specLty";
                          withInternals(fn () =>
                           debugPrint("entEnv: ",
                                 (fn pps => fn ee => 
                                  PPModules.ppEntityEnv pps (ee,SE.empty,12)),
                                  entEnv));
                          debugmsg ("$specLty: should have printed entEnv");
                          raise EE.Unbound))

                  fun mapty t = 
		      let val t' = transty t 
			      handle _ => (bug "specLty[mapty,transty]")
		      in toLty penv depth t'  
			 handle _ => bug "specLty[mapty]"
		      end

               in case spec
                   of VALspec{spec=typ,...} => 
                        (debugmsg "--specLty[VALspec]";
			 g(rest, entEnv, (mapty typ)::ltys))
                    | CONspec{spec=DATACON{rep=DA.EXN _, 
                                           typ, ...}, ...} => 
                        let val _ = debugmsg "--specLty[CONspec]\n"
			    val argt = 
                              if BT.isArrowType typ then  
                                   #1(LT.ltd_parrow (mapty typ))
                              else LT.ltc_unit
                         in g(rest, entEnv, (LT.ltc_etag argt)::ltys)
                        end
                    | CONspec{spec=DATACON _, ...} =>
                        (debugmsg "--specLty[CONspec]"; g(rest, entEnv, ltys))
                    | _ => bug "unexpected spec in specLty"
              end
      val res = g (elements, entEnv, [])
      val _  = debugmsg ("<<specLty")
   in res
  end

(* sign is paramsig
   rlzn is argRlzn
 *) 
and strMetaLty (sign, rlzn as { entities, ... }: strEntity, 
		penv : primaryEnv, depth, compInfo, envop) =
    case (sign, ModulePropLists.strEntityLty rlzn) (* check for momoized value *)
     of (_, SOME (lt, od)) => LT.lt_adj(lt, od, depth)
      | (SIG { elements, ... }, NONE) => 
	let val entenv' = (case envop 
			    of NONE => entities
			     | SOME env => EE.atop(entities, env))
	    val ltys = specLty (elements, entities, penv, depth, compInfo)
            val lt = LT.ltc_str(ltys)
        in
	    ModulePropLists.setStrEntityLty (rlzn, SOME(lt, depth));
	    lt
        end
      | _ => bug "unexpected sign and rlzn in strMetaLty"

and strRlznLty (sign, rlzn : strEntity, penv : primaryEnv, depth, compInfo) =
    case (sign, ModulePropLists.strEntityLty rlzn)
     of (sign, SOME (lt,od)) => LT.lt_adj(lt, od, depth)
      | _ => (debugmsg ">>strRlznLty[strEntityLty NONE]";
	      strMetaLty(sign, rlzn, penv, depth, compInfo, NONE))

and fctRlznLty (sign, rlzn, penv : primaryEnv, depth, compInfo) = 
    case (sign, ModulePropLists.fctEntityLty rlzn, rlzn)
      of (_, SOME (lt, od), _) => LT.lt_adj(lt, od, depth)
       | (fs as FSIG{paramsig, bodysig, ...}, _,
         {closureEnv=env,primaries,paramEnv, ...}) =>
        let val _ = debugmsg ">>fctRlznLty[instParam]"
            val nd = DI.next depth

	    (* [GK 4/30/09] Closure environments map entity paths to 
               types that have no connection to the stamps of the formal 
               types they map. 
               
               [GK 4/24/09] We must somehow account for the closure 
	       environment env. It contains important realization 
	       information such as parameter information from 
               partially applied curried functors. 
             *)

            (* [DBM, 5/19/09] here we could use the primaries stored
             * in the LAMBDA fct expression, but we would need the
	     * original instantiation realization for the paramsig created
	     * during elaboration (or maybe not -- it could be that kind
	     * calculation is insensitive to which rlzn is used.
	     * Alternatively, as is done here, we can re-instantiate
	     * paramsig and use the new primaries and rlzn to calculate
	     * the kinds.
	     * We also need to reuse the parameter instantiation for the call
	     * of evalApp below. Whichever instantiation is used to calculate
	     * the penv_layer must also be used for evalApp so that the
	     * type variable bindings (via stamps) are correlated with their
	     * occurrences in the body rlzn after evalApp.
	     *)

	    val {rlzn=paramRlzn, primaries=_} = 
		INS.instFormal{sign=paramsig,entEnv=env,
			       rpath=InvPath.IPATH[], compInfo=compInfo,
			       region=SourceMap.nullRegion}

	    val _ = debugmsg ">>parameter kinds"
	    val primaryBindings =
		map (FctKind.primaryToBind (compInfo, paramEnv))
		    primaries
	    val ks = map #2 (primaryBindings)   (* extract kinds *)

	    val _ = if !debugging 
		    then (debugmsg "====================";
(*			  withInternals(fn () =>
			    debugPrint("paramRlzn: ",
				       (fn pps => fn ee =>
					PPModules.ppEntity pps (ee,SE.empty,100)),
				       (STRent paramRlzn))); *)
			  withInternals(fn () =>
			    debugPrint("closure: ",
				       (fn pps => fn env =>
					PPModules.ppEntityEnv pps (env,SE.empty,100)),
				       env));
			  debugmsg "====================")
		    else ()

	    val _ = debugmsg ">>strMetaLty"
            val paramLty = strMetaLty(paramsig, paramRlzn, penv, nd, compInfo,
				     SOME env)
		handle _ => bug "fctRlznLty 2"
		     
	    val _ = debugmsg (">>fctRlznLty calling evalApp nd "^DI.dp_print nd)
            (* use evalApp to propagate parameter elements and generate new body
	     * elements *)
            val bodyRlzn = 
                EV.evalApp(rlzn, paramRlzn, EPC.initContext,
                           IP.empty, compInfo)
	    val _ = if !debugging
		    then (debugmsg "==================";
			  withInternals(fn () =>
                           debugPrint("evalApp: ",
                                 (fn pps => fn ee => 
                                  PPModules.ppEntity pps (ee,SE.empty,100)),
                                  (STRent bodyRlzn)));
			  withInternals(fn () =>
                           debugPrint("paramRlzn: ",
                                 (fn pps => fn ee => 
                                  PPModules.ppEntity pps (ee,SE.empty,100)),
                                  (STRent paramRlzn)));
			  debugmsg "====================")
		    else ()
	    val _ = debugmsg ">>strRlznLty: functor body"
	    (* [GK 5/5/09] Ideally, we want to be able to compute this 
	       without having to appeal to EV.evalApp to get bodyRlzn.
	       [DBM 5/19/09] This should be possible. It will require
	       "decompiling" the LAMBDA expression in the functor rlzn. *)

	    (* add "bindings" for the primaries from the parameter
	     * instantiation, so that references to them in the body str can be
	     * translated into type variables. *)
	    val innerPenv = primaries :: penv

            (* [DBM: 5/19/09] Does the bodyLty have the kind that was (would be?)
	     * calculated for the functor signature? I.e. is it a tuple of ltys
	     * corresponding to the primaries of bodysig? *)
	    val bodyLty = strRlznLty(bodysig, bodyRlzn, innerPenv, nd, compInfo)

	    val _ = debugmsg "<<strRlznLty: functor body"

            val lt = LT.ltc_poly(ks, [LT.ltc_fct([paramLty],[bodyLty])])
        in
	    ModulePropLists.setFctEntityLty (rlzn, SOME (lt, depth));  (* memoize *)
	    debugmsg "<<fctRlznLty";
	    lt
        end 
      | _ => bug "fctRlznLty"

and strLty (str as STR { sign, rlzn, ... }, penv : primaryEnv, depth, compInfo) =
    (case ModulePropLists.strEntityLty rlzn
      of SOME (lt, od) => LT.lt_adj(lt, od, depth)
       | NONE =>
         let val _ = debugmsg ">>strLty"
	     val lt = strRlznLty(sign, rlzn, penv, depth, compInfo)
          in ModulePropLists.setStrEntityLty (rlzn, SOME(lt, depth));
	     debugmsg "<<strLty";
	     lt
         end)
  | strLty _ = bug "unexpected structure in strLty"

and fctLty (fct as FCT { sign, rlzn, ... }, penv : primaryEnv, depth, compInfo) =
    (debugmsg ">>fctLty";
     (case ModulePropLists.fctEntityLty rlzn of
	 SOME (lt,od) => (debugmsg "--fctLty[proplist] "; 
			  LT.lt_adj(lt, od, depth))
       | NONE =>
         let val _ = debugmsg ">>fctLty[computing]"
	     val lt = fctRlznLty(sign, rlzn, penv, depth, compInfo) 
	  in ModulePropLists.setFctEntityLty (rlzn, SOME(lt,depth));
	     debugmsg "<<fctLty";
	     lt
         end))
  | fctLty _ = bug "unexpected functor in fctLty"

end (* toplevel local *)
end (* structure TransTypes *)




(****************************************************************************
 *           A HASH-CONSING VERSION OF THE ABOVE TRANSLATIONS               *
 ****************************************************************************)

(*
structure MIDict = RedBlackMapFn(struct type ord_key = ModuleId.modId
                                     val compare = ModuleId.cmp
                              end)
*)

(*
      val m1 = ref (MIDict.mkDict())   (* modid (tycon) -> LT.tyc *)
      val m2 = ref (MIDict.mkDict())   (* modid (str/fct) -> LT.lty *)

      fun tycTycLook (t as (GENtyc _ | DEFtyc _), d) = 
            let tid = MU.tycId t
             in (case MIDict.peek(!m1, tid)
                  of SOME (t', od) => LT.tc_adj(t', od, d) 
                   | NONE => 
                       let val x = tyconToTyc (t, penv, d)
                           val _ = (m1 := TcDict.insert(!m1, tid, (x, d)))
                        in x
                       end)
            end
        | tycTycLook x = tyconToTyc tycTycLook x

(*
      val toTyc = toTyc tycTycLook
      val toLty = toTyc tycTycLook
*)
      val coreDict = (toTyc, toLty)

      fun strLtyLook (s as STR _, d) = 
            let sid = MU.strId s
             in (case MIDict.peek(!m2, sid)
                  of SOME (t', od) => LT.lt_adj(t', od, d)
                   | NONE => 
                       let val x = strLty (coreDict, strLtyLook, 
                                           fctLtyLook) (s, d)
                           val _ = (m2 := TcDict.insert(!m2, sid, (x, d)))
                        in x
                       end)
            end
        | strLtyLook x = strLty (coreDict, strLtyLook, fctLtyLook)

      and fctLtyLook (f as FCT _, d) = 
            let fid = fctId f
             in (case MIDict.peek(!m2, fid)
                  of SOME (t', od) => LT.lt_adj(t', od, d)
                   | NONE => 
                       let val x = fctLty (tycTycLook, strLtyLook, 
                                           fctLtyLook) (s, d)
                           val _ = (m2 := TcDict.insert(!m2, fid, (x, d)))
                        in x
                       end)
            end
        | fctLtyLook x = fctLty (coreDict, strLtyLook, fctLtyLook)
*)

