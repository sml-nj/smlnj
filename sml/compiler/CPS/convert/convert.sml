(* convert.sml
 *
 * COPYRIGHT (c) 2017 The Fellowship of SML/NJ (http://www.smlnj.org)
 * All rights reserved.
 *)

(***************************************************************************
 *                         IMPORTANT NOTES                                 *
 *                                                                         *
 *          The CPS code generated by this phase should not                *
 *                use OFFSET and RECORD accesspath SELp.                   *
 *                  generated by this module.                              *
 ***************************************************************************)
signature CONVERT =
  sig

    val convert : FLINT.prog -> CPS.function

  end (* signature CONVERT *)

functor Convert (MachSpec : MACH_SPEC) : CONVERT =
  struct

    structure DA = Access
    structure LT = LtyExtern
    structure LV = LambdaVar
    structure AP = Primop
    structure DI = DebIndex
    structure F  = FLINT
    structure FU = FlintUtil
    structure M  = IntBinaryMap
    structure CU = CPSUtil

    open CPS

    fun bug s = ErrorMsg.impossible ("Convert: " ^ s)
    val say = Control.Print.say
    val mkv = fn _ => LV.mkLvar()
    val cplv = LV.dupLvar
    fun mkfn f = let val v = mkv() in f v end
    val ident = fn le => le
    val OFFp0 = OFFp 0

  (* integer types/values *)
    local
      val tt = {sz = Target.defaultIntSz, tag = true}
      fun bt sz = {sz = sz, tag = false}
    in
    val tagIntTy = NUMt tt
    fun tagInt n = NUM{ival = n, ty = tt}
    fun tagInt' n = tagInt(IntInf.fromInt n)
    fun boxIntTy sz = NUMt(bt sz)
    fun boxInt (sz, i) = NUM{ival = i, ty = bt sz}
    end

    (* testing if two values are equivalent lvar values *)
    fun veq (VAR x, VAR y) = (x = y)
      | veq _ = false

    local
      structure PCT = PrimCTypes
      structure CT = CTypes
    in
    (* convert PrimCTypes.c_proto to MLRISC's CTypes.c_proto *)
    fun cvtCProto {conv, retTy, paramTys} : CTypes.c_proto = let
	  fun cvtIntTy PCT.I_char = CT.I_char
	    | cvtIntTy PCT.I_short = CT.I_short
	    | cvtIntTy PCT.I_int = CT.I_int
	    | cvtIntTy PCT.I_long = CT.I_long
	    | cvtIntTy PCT.I_long_long = CT.I_long_long
	  fun cvtTy PCT.C_void = CT.C_void
	    | cvtTy PCT.C_float = CT.C_float
	    | cvtTy PCT.C_double = CT.C_double
	    | cvtTy PCT.C_long_double = CT.C_long_double
	    | cvtTy (PCT.C_unsigned ity) = CT.C_unsigned(cvtIntTy ity)
	    | cvtTy (PCT.C_signed ity) = CT.C_signed(cvtIntTy ity)
	    | cvtTy PCT.C_PTR = CT.C_PTR
	    | cvtTy (PCT.C_ARRAY(ty, n)) = CT.C_ARRAY(cvtTy ty, n)
	    | cvtTy (PCT.C_STRUCT tys) = CT.C_STRUCT(List.map cvtTy tys)
	    | cvtTy (PCT.C_UNION tys) = CT.C_UNION(List.map cvtTy tys)
	  in
	    {conv = conv, retTy = cvtTy retTy, paramTys = List.map cvtTy paramTys}
	  end
    end (* local *)

  (***************************************************************************
   *              CONSTANTS AND UTILITY FUNCTIONS                            *
   ***************************************************************************)

    fun unwrapFlt (sz, u, x, ce) = PURE(P.unwrap(P.FLOAT sz),  [u], x, FLTt sz, ce)
    fun unwrapInt (sz, u, x, ce) = PURE(P.unwrap(P.INT sz), [u], x, boxIntTy sz, ce)
    fun wrapFlt (sz, u, x, ce) = PURE(P.wrap(P.FLOAT sz), [u], x, CU.BOGt, ce)
    fun wrapInt (sz, u, x, ce) = PURE(P.wrap(P.INT sz), [u], x, CU.BOGt, ce)

    fun all_float (FLTt _::r) = all_float r
      | all_float (_::r) = false
      | all_float [] = true

    fun selectFL(i,u,x,ct,ce) = SELECT(i,u,x,ct,ce)

    fun selectNM(i,u,x,ct,ce) = (case ct
	   of FLTt sz => mkfn(fn v => SELECT(i, u, v, CU.BOGt, unwrapFlt(sz, VAR v, x, ce)))
	    | NUMt{sz, tag=false} =>
		mkfn(fn v => SELECT(i, u, v, CU.BOGt, unwrapInt(sz, VAR v, x, ce)))
	    | _ => SELECT(i, u, x, ct, ce)
	  (* end case *))

    fun recordFL(ul,_,w,ce) =
	  RECORD(RK_FBLOCK, map (fn u => (u,OFFp 0)) ul, w, ce)

    fun recordNM(ul,ts,w,ce) =
      let fun g (FLTt sz::r,u::z,l,h) =
		mkfn(fn v => g(r, z, (VAR v,OFFp 0)::l, fn ce => h(wrapFlt(sz, u, v, ce))))
	    | g (NUMt{sz, tag=false}::r,u::z,l,h) =
		mkfn(fn v => g(r, z, (VAR v,OFFp 0)::l, fn ce => h(wrapInt(sz, u, v, ce))))
	    | g (NUMt{tag=false, sz} ::_, _, _, _) =
		  raise Fail("unsupported NUMt size = " ^ Int.toString sz) (* 64BIT: FIXME *)
	    | g (_::r,u::z,l,h) = g(r, z, (u,OFFp0)::l, h)
	    | g ([],[],l,h) = (rev l, h)
	    | g _ = bug "unexpected in recordNM in convert"

	  val (nul,header) = g(ts,ul,[],fn x => x)
       in header(RECORD(RK_RECORD,nul,w,ce))
      end

  (***************************************************************************
   *              UTILITY FUNCTIONS FOR PROCESSING THE PRIMOPS               *
   ***************************************************************************)

  (* numkind: AP.numkind -> P.numkind *)
    fun numkind (AP.INT bits) = P.INT bits
      | numkind (AP.UINT bits) = P.UINT bits
      | numkind (AP.FLOAT bits) = P.FLOAT bits

  (* cmpop: {oper: AP.cmpop, kind: AP.numkind} -> P.branch *)
    fun cmpop stuff = (case stuff
	   of {oper,kind=AP.FLOAT size} => let
		val rator = (case oper
		      of AP.GT => P.fGT
		       | AP.GTE  => P.fGE
		       | AP.LT   => P.fLT
		       | AP.LTE  => P.fLE
		       | AP.EQL  => P.fEQ
		       | AP.NEQ  => P.fULG
		       | AP.FSGN => P.fsgn
		       | _       => bug "cmpop:kind=AP.FLOAT"
		     (* end case *))
		in
		  P.fcmp{oper= rator, size=size}
		end
	    | {oper, kind} => let
		fun check (_, AP.UINT _) = ()
		  | check (oper, _) = bug ("check" ^ oper)
		fun c AP.GT  = P.GT
		  | c AP.GTE = P.GTE
		  | c AP.LT  = P.LT
		  | c AP.LTE = P.LTE
		  | c AP.LEU = (check ("leu", kind); P.LTE )
		  | c AP.LTU = (check ("ltu", kind); P.LT )
		  | c AP.GEU = (check ("geu", kind); P.GTE )
		  | c AP.GTU = (check ("gtu", kind); P.GT )
		  | c AP.EQL = P.EQL
		  | c AP.NEQ = P.NEQ
		  | c AP.FSGN = bug "cmpop:kind=AP.UINT"
		in
		  P.cmp{oper=c oper, kind=numkind kind}
		end
	  (* end case *))

  (* map_branch:  AP.primop -> P.branch *)
    fun map_branch p = (case p
	   of AP.BOXED => P.boxed
	    | AP.UNBOXED => P.unboxed
	    | AP.CMP stuff => cmpop stuff
	    | AP.PTREQL => P.peql
	    | AP.PTRNEQ => P.pneq
	    | _ => bug "unexpected primops in map_branch"
	  (* end case *))

  (* primwrap: cty -> P.pure *)
    fun primwrap (NUMt{sz, ...}) = P.wrap(P.INT sz)
      | primwrap (FLTt sz) = P.wrap(P.FLOAT sz)
      | primwrap _ = P.box

  (* primunwrap: cty -> P.pure *)
    fun primunwrap (NUMt{sz, ...}) = P.unwrap(P.INT sz)
      | primunwrap (FLTt sz) = P.unwrap(P.FLOAT sz)
      | primunwrap _ = P.unbox

  (* arithop: AP.arithop -> P.arithop *)
    fun arithop AP.NEG = P.NEG
      | arithop AP.ABS = P.ABS
      | arithop AP.FSQRT = P.FSQRT
      | arithop AP.FSIN = P.FSIN
      | arithop AP.FCOS = P.FCOS
      | arithop AP.FTAN = P.FTAN
      | arithop AP.NOTB = P.NOTB
      | arithop AP.QUOT = P.QUOT
      | arithop AP.REM = P.REM
      | arithop AP.DIV = P.DIV
      | arithop AP.MOD = P.MOD
      | arithop AP.ADD = P.ADD
      | arithop AP.SUB = P.SUB
      | arithop AP.MUL = P.MUL
      | arithop AP.FDIV = P.FDIV
      | arithop AP.LSHIFT = P.LSHIFT
      | arithop AP.RSHIFT = P.RSHIFT
      | arithop AP.RSHIFTL = P.RSHIFTL
      | arithop AP.ANDB = P.ANDB
      | arithop AP.ORB = P.ORB
      | arithop AP.XORB = P.XORB

  (* a temporary classifier of various kinds of CPS primops *)
    datatype pkind
      = PKS of P.setter
      | PKP of P.pure
      | PKL of P.looker
      | PKA of P.arith

  (* map_primop: AP.primop -> pkind *)
    fun map_primop p = (case p
	   of AP.TEST(from,to) =>   PKA (P.test(from, to))
	    | AP.TESTU(from,to) =>  PKA (P.testu(from, to))
	    | AP.COPY(from,to) =>   PKP (P.copy(from,to))
	    | AP.EXTEND(from,to) => PKP (P.extend(from, to))
	    | AP.TRUNC(from,to) =>  PKP (P.trunc(from, to))

	    | AP.TEST_INF to => PKA (P.test_inf to)
	    | AP.TRUNC_INF to => PKP (P.trunc_inf to)
	    | AP.COPY_INF from => PKP (P.copy_inf from)
	    | AP.EXTEND_INF from => PKP (P.extend_inf from)

	    | AP.ARITH{oper,kind,overflow=true} =>
		PKA(P.arith{oper=arithop oper,kind=numkind kind})
	    | AP.ARITH{oper,kind,overflow=false} =>
		PKP(P.pure_arith{oper=arithop oper,kind=numkind kind})
	    | AP.ROUND{floor,fromkind,tokind} =>
		PKA(P.round{floor=floor, fromkind=numkind fromkind,
			    tokind=numkind tokind})
	    | AP.REAL{fromkind,tokind} =>
		PKP(P.real{tokind=numkind tokind, fromkind=numkind fromkind})

	    | AP.SUBSCRIPTV => PKP (P.subscriptv)
	    | AP.MAKEREF =>    PKP (P.makeref)
	    | AP.LENGTH =>     PKP (P.length)
	    | AP.OBJLENGTH =>  PKP (P.objlength)
	    | AP.GETTAG =>     PKP (P.gettag)
	    | AP.MKSPECIAL =>  PKP (P.mkspecial)
 (*         | AP.THROW =>      PKP (P.cast) *)
	    | AP.CAST =>       PKP (P.cast)
	    | AP.MKETAG =>     PKP (P.makeref)
	    | AP.NEW_ARRAY0 => PKP (P.newarray0)
	    | AP.GET_SEQ_DATA => PKP (P.getseqdata)
	    | AP.SUBSCRIPT_REC => PKP (P.recsubscript)
	    | AP.SUBSCRIPT_RAW64 => PKP (P.raw64subscript)

	    | AP.SUBSCRIPT => PKL (P.subscript)
	    | AP.NUMSUBSCRIPT{kind,immutable=false,checked=false} =>
		  PKL(P.numsubscript{kind=numkind kind})
	    | AP.NUMSUBSCRIPT{kind,immutable=true,checked=false} =>
		  PKP(P.pure_numsubscript{kind=numkind kind})
	    | AP.DEREF =>     PKL(P.!)
	    | AP.GETHDLR =>   PKL(P.gethdlr)
	    | AP.GETVAR  =>   PKL(P.getvar)
	    | AP.GETSPECIAL =>PKL(P.getspecial)

	    | AP.SETHDLR => PKS(P.sethdlr)
	    | AP.NUMUPDATE{kind,checked=false} =>
		  PKS(P.numupdate{kind=numkind kind})
	    | AP.UNBOXEDUPDATE => PKS(P.unboxedupdate)
	    | AP.UPDATE => PKS(P.update)
	    | AP.ASSIGN => PKS(P.assign)
	    | AP.UNBOXEDASSIGN => PKS(P.unboxedassign)
	    | AP.SETVAR => PKS(P.setvar)
	    | AP.SETSPECIAL => PKS(P.setspecial)

	    | AP.RAW_LOAD nk => PKL (P.rawload { kind = numkind nk })
	    | AP.RAW_STORE nk => PKS (P.rawstore { kind = numkind nk })
	    | AP.RAW_RECORD{ fblock = false } => PKP (P.rawrecord (SOME RK_I32BLOCK))
	    | AP.RAW_RECORD{ fblock = true } => PKP (P.rawrecord (SOME RK_FBLOCK))

	    | _ => bug ("bad primop in map_primop: " ^ (AP.prPrimop p) ^ "\n")
	  (* end case *))

  (***************************************************************************
   *                  SWITCH OPTIMIZATIONS AND COMPILATIONS                  *
   ***************************************************************************)

    fun switchGen rename = Switch.switch { rename = rename }

  (***************************************************************************
   *       UTILITY FUNCTIONS FOR DEALING WITH META-LEVEL CONTINUATIONS       *
   ***************************************************************************)
  (* an abstract representation of the meta-level continuation *)
    datatype mcont = MCONT of {cnt: value list -> cexp, ts: cty list}

  (* appmc : mcont * value list -> cexp *)
    fun appmc (MCONT{cnt, ...}, vs) = cnt(vs)

  (* makmc : (value list -> cexp) * cty list -> cexp *)
    fun makmc (cnt, ts) = MCONT{cnt=cnt, ts=ts}

  (* rttys : mcont -> cty list *)
    fun rttys (MCONT{ts, ...}) = ts

  (***************************************************************************
   *                        THE MAIN FUNCTION                                *
   *                   convert : F.prog -> CPS.function                      *
   ***************************************************************************)
    fun convert fdec =
     let val {getLty=getlty, cleanUp, ...} = Recover.recover (fdec, true)
	 val ctypes = map CU.ctype
	 fun res_ctys f =
	   let val lt = getlty (F.VAR f)
	    in if LT.ltp_fct lt then ctypes (#2(LT.ltd_fct lt))
	       else if LT.ltp_arrow lt then ctypes (#3(LT.ltd_arrow lt))
		    else [CU.BOGt]
	   end
	 fun get_cty v = CU.ctype (getlty v)
	 fun is_float_record u =
	   LT.ltw_tyc (getlty u,
		       fn tc => LT.tcw_tuple (tc, fn l => all_float (map CU.ctyc l),
					      fn _ => false),
		       fn _ => false)

	 val bogus_cont = mkv()
	 fun bogus_header ce =
	   let val bogus_knownf = mkv()
	    in FIX([(KNOWN, bogus_knownf, [mkv()], [CU.BOGt],
		   APP(VAR bogus_knownf, [STRING "bogus"]))],
		   FIX([(CONT, bogus_cont, [mkv()], [CU.BOGt],
			APP(VAR bogus_knownf, [STRING "bogus"]))], ce))
	   end

	 local exception Rename
	       val m : value IntHashTable.hash_table =
		   IntHashTable.mkTable(32, Rename)
	 in
	 (* F.lvar -> CPS.value *)
	 fun rename v = IntHashTable.lookup m v handle Rename => VAR v

	 (* F.lvar * CPS.value -> unit *)
	 fun newname (v, w) =
	   (case w of VAR w' => LV.sameName (v, w') | _ => ();
	    IntHashTable.insert m (v, w))

	 (* F.lvar list * CPS.value list -> unit *)
	 fun newnames (v::vs, w::ws) = (newname(v,w); newnames(vs, ws))
	   | newnames ([], []) = ()
	   | newnames _ = bug "unexpected case in newnames"

	 (* isEta : cexp * value list -> value option *)
	 fun isEta (APP(w as VAR lv, vl), ul) =
	     (* If the function is in the global renaming table and it's
	      * renamed to itself, then it's most likely a while loop and
	      * should *not* be eta-reduced *)
	     if ((case IntHashTable.lookup m lv of
		      VAR lv' => lv = lv'
		    | _ => false)
		 handle Rename => false) then NONE else
		 let fun h (x::xs, y::ys) =
			 if (veq(x, y)) andalso (not (veq(w, y)))
			 then h(xs, ys) else NONE
		       | h ([], []) = SOME w
		       | h _ = NONE
		 in h(ul, vl)
		 end
	   | isEta _ = NONE

	 end (* local of Rename *)

	 (* preventEta : mcont -> (cexp -> cexp) * value *)
	 fun preventEta (MCONT{cnt=c, ts=ts}) =
	     let val vl = map mkv ts
		 val ul = map VAR vl
		 val b = c ul
	     in case isEta(b, ul)
		 of SOME w => (ident, w)
		  | NONE => let val f = mkv()
		    in (fn x => FIX([(CONT,f,vl,ts,b)],x), VAR f)
		    end
	     end (* function preventEta *)

	 (* switch optimization *)
	 val switch = switchGen rename

	 (* lpvar : F.value -> value *)
	 fun lpvar (F.VAR v) = rename v
	   | lpvar (F.INT{ival, ty=32}) = boxInt(32, ival)
	   | lpvar (F.WORD{ival, ty=32}) = boxInt(32, ival)
	   | lpvar (F.INT{ival, ty=31}) = tagInt ival
	   | lpvar (F.WORD{ival, ty=31}) = tagInt ival
	   | lpvar (F.REAL r) = REAL r
	   | lpvar (F.STRING s) = STRING s
	   | lpvar v = bug(concat["lpvar (", PPFlint.toStringValue v, ")"])

	 (* lpvars : F.value list -> value list *)
	 fun lpvars vl =
	   let fun h([], z) = rev z
		 | h(a::r, z) = h(r, (lpvar a)::z)
	    in h(vl, [])
	   end

	 (* loop : F.lexp * (value list -> cexp) -> cexp *)
	 fun loop' m (le, c) = let val loop = loop' m
	 in case le
	     of F.RET vs => appmc(c, lpvars vs)
	      | F.LET(vs, e1, e2) =>
		  let val kont =
			makmc (fn ws => (newnames(vs, ws); loop(e2, c)),
			       map (get_cty o F.VAR) vs)
		   in loop(e1, kont)
		  end

	      | F.FIX(fds, e) =>
		(* lpfd : F.fundec -> function *)
		let fun lpfd ((fk, f, vts, e) : F.fundec) =
			let val k = mkv()
			    val cl = CNTt::(map (CU.ctype o #2) vts)
			    val kont = makmc (fn vs => APP(VAR k, vs), res_ctys f)
			    val (vl,body) =
				case fk
				 of {isrec=SOME(_,F.LK_TAIL),...} => let
				     (* for tail recursive loops, we create a
				      * local function that takes its continuation
				      * from the environment *)
				     val f' = cplv f
				     (* here we add a dumb entry for f' in the
				      * global renaming table just so that isEta
				      * can avoid eta-reducing it *)
				     val _ = newname(f', VAR f')
				     val vl = k::(map (cplv o #1) vts)
				     val vl' = map #1 vts
				     val cl' = map (CU.ctype o #2) vts
				 in
				     (vl,
				      FIX([(KNOWN_TAIL, f', vl', cl',
					    (* add the function to the tail map *)
					    loop' (M.insert(m,f,f')) (e, kont))],
					  APP(VAR f', map VAR (tl vl))))
				 end
				  | _ => (k::(map #1 vts), loop(e, kont))
			in (ESCAPE, f, vl, cl, body)
			end
		in FIX(map lpfd fds, loop(e, c))
		end
	      | F.APP(f as F.VAR lv, vs) =>
		(* first check if it's a recursive call to a tail loop *)
		(case M.find(m, lv)
		  of SOME f' => APP(VAR f', lpvars vs)
		   | NONE =>
		     (* code for the non-tail case.
		      * Sadly this is *not* exceptional *)
		     let val (hdr, F) = preventEta c
			 val vf = lpvar f
			 val ul = lpvars vs
		     in hdr(APP(vf, F::ul))
		     end)
	      | F.APP _ => bug "unexpected APP in convert"

	      | (F.TFN _ | F.TAPP _) =>
		  bug "unexpected TFN and TAPP in convert"

	      | F.RECORD(F.RK_VECTOR _, [], v, e) =>
		  bug "zero length vectors in convert"
	      | F.RECORD(rk, [], v, e) => let
		  val _ = newname(v, tagInt 0)
		  in
		    loop(e, c)
		  end
	      | F.RECORD(rk, vl, v, e) =>
		  let val ts = map get_cty vl
		      val nvl = lpvars vl
		      val ce = loop(e, c)
		   in case rk
		       of F.RK_TUPLE _ =>
			   if (all_float ts) then recordFL(nvl, ts, v, ce)
			   else recordNM(nvl, ts, v, ce)
			| F.RK_VECTOR _ =>
			   RECORD(RK_VECTOR, map (fn x => (x, OFFp0)) nvl, v, ce)
			| _ => recordNM(nvl, ts, v, ce)
		  end
	      | F.SELECT(u, i, v, e) =>
		  let val ct = get_cty (F.VAR v)
		      val nu = lpvar u
		      val ce = loop(e, c)
		   in if is_float_record u then selectFL(i, nu, v, ct, ce)
		      else selectNM(i, nu, v, ct, ce)
		  end

	      | F.SWITCH(e,l,[a as (F.DATAcon((_,DA.CONSTANT 0,_),_,_),_),
			      b as (F.DATAcon((_,DA.CONSTANT 1,_),_,_),_)],
			 NONE) =>
		  loop(F.SWITCH(e,l,[b,a],NONE),c)
	      | F.SWITCH (u, sign, l, d) =>
		  let val (header,F) = preventEta c
		      val kont = makmc(fn vl => APP(F, vl), rttys c)
		      val body = let
			    val df = mkv()
			    fun proc (cn as (F.DATAcon(dc, _, v)), e) =
				  (cn, loop (F.LET([v], F.RET [u], e), kont))
			      | proc (cn, e) = (cn, loop(e, kont))
			    val b = switch {
				    arg = lpvar u, sign = sign,
				    cases = map proc l,
				    default = APP(VAR df, [tagInt 0])
				  }
			    in case d
				 of NONE => b
				  | SOME de => FIX([(CONT, df, [mkv()], [tagIntTy],
						   loop(de, kont))], b)
			    end
		   in header(body)
		  end
	      | F.CON(dc, ts, u, v, e) =>
		  bug "unexpected case CON in cps convert"

	      | F.RAISE(u, lts) =>
		  let (* execute the continuation for side effects *)
		      val _ = appmc(c, (map (fn _ => VAR(mkv())) lts))
		      val h = mkv()
		   in LOOKER(P.gethdlr, [], h, FUNt,
			     APP(VAR h,[VAR bogus_cont,lpvar u]))
		  end
	      | F.HANDLE(e,u) => (* recover type from u *)
		  let val (hdr, F) = preventEta c
		      val h = mkv()
		      val kont =
			makmc (fn vl =>
				 SETTER(P.sethdlr, [VAR h], APP(F, vl)),
			       rttys c)
		      val body =
			let val k = mkv() and v = mkv()
			 in FIX([(ESCAPE, k, [mkv(), v], [CNTt, CU.BOGt],
				  SETTER(P.sethdlr, [VAR h],
					 APP(lpvar u, [F, VAR v])))],
				SETTER(P.sethdlr, [VAR k], loop(e, kont)))
			end
		   in LOOKER(P.gethdlr, [], h, FUNt, hdr(body))
		  end

	      | F.PRIMOP((_,p as (AP.CALLCC | AP.CAPTURE),_,_), [f], v, e) =>
		  let val (kont_decs, F) =
			let val k = mkv()
			    val ct = get_cty f
			 in ([(CONT, k, [v], [ct], loop(e, c))], VAR k)
			end

		      val (hdr1,hdr2) =
			(case p
			  of AP.CALLCC =>
			      mkfn(fn h =>
			       (fn e => SETTER(P.sethdlr, [VAR h], e),
				fn e => LOOKER(P.gethdlr, [], h, CU.BOGt, e)))
			   | _ => (ident, ident))

		      val (ccont_decs, ccont_var) =
			let val k = mkv() (* captured continuation *)
			    val x = mkv()
			 in ([(ESCAPE, k, [mkv(), x], [CNTt, CU.BOGt],
			       hdr1(APP(F, [VAR x])))], k)
			end
		   in FIX(kont_decs,
			hdr2(FIX(ccont_decs,
				 APP(lpvar f, [F, VAR ccont_var]))))
		  end

	      | F.PRIMOP((_,AP.ISOLATE,lt,ts), [f], v, e) =>
		  let val (exndecs, exnvar) =
			let val h = mkv() and z = mkv() and x = mkv()
			 in ([(ESCAPE, h, [z, x], [CNTt, CU.BOGt],
			     APP(VAR bogus_cont, [VAR x]))], h)
			end
		      val newfdecs =
			let val nf = v and z = mkv() and x = mkv()
			 in [(ESCAPE, v, [z, x], [CNTt, CU.BOGt],
			       SETTER(P.sethdlr, [VAR exnvar],
				 APP(lpvar f, [VAR bogus_cont, VAR x])))]
			end
		   in FIX(exndecs, FIX(newfdecs, loop(e, c)))
		  end

	      | F.PRIMOP(po as (_,AP.THROW,_,_), [u], v, e) =>
		  (newname(v, lpvar u); loop(e, c))
    (*            PURE(P.wrap, [lpvar u], v, FUNt, c(VAR v))          *)

	      | F.PRIMOP(po as (_,AP.WCAST,_,_), [u], v, e) =>
		  (newname(v, lpvar u); loop(e, c))

	      | F.PRIMOP(po as (_,AP.WRAP,_,_), [u], v, e) =>
		  let val ct = CU.ctyc(FU.getWrapTyc po)
		   in PURE(primwrap ct, [lpvar u], v, CU.BOGt, loop(e, c))
		  end
	      | F.PRIMOP(po as (_,AP.UNWRAP,_,_), [u], v, e) =>
		  let val ct = CU.ctyc(FU.getUnWrapTyc po)
		   in PURE(primunwrap ct, [lpvar u], v, ct, loop(e, c))
		  end

	      | F.PRIMOP(po as (_,AP.MARKEXN,_,_), [x,m], v, e) =>
		  let val bty = LT.ltc_void
		      val ety = LT.ltc_tuple[bty,bty,bty]
		      val (xx,x0,x1,x2) = (mkv(),mkv(),mkv(),mkv())
		      val (y,z,z') = (mkv(),mkv(),mkv())
		   in PURE(P.unbox, [lpvar x], xx, CU.ctype ety,
			SELECT(0,VAR xx,x0,CU.BOGt,
			  SELECT(1,VAR xx,x1,CU.BOGt,
			    SELECT(2,VAR xx,x2,CU.BOGt,
			      RECORD(RK_RECORD,[(lpvar m, OFFp0),
						(VAR x2, OFFp0)], z,
				     PURE(P.box,[VAR z],z',CU.BOGt,
				       RECORD(RK_RECORD,[(VAR x0,OFFp0),
							 (VAR x1,OFFp0),
							 (VAR z', OFFp0)],
					      y,
					  PURE(P.box,[VAR y],v,CU.BOGt,
					       loop(e,c)))))))))
		  end

	      | F.PRIMOP ((_,AP.RAW_CCALL NONE,_,_), _::_::a::_,v,e) =>
		(* code generated here should never be executed anyway,
		 * so we just fake it... *)
		(print "*** pro-forma raw-ccall\n";
		 newname (v, lpvar a); loop(e,c))

	      | F.PRIMOP ((_,AP.RAW_CCALL (SOME i),lt,ts),f::a::_::_,v,e) => let
		    val { c_proto, ml_args, ml_res_opt, reentrant } = i
		    val c_proto = cvtCProto c_proto
		    fun cty AP.CCR64 = FLTt 64		(* REAL32: FIXME *)
		      | cty AP.CCI32 = boxIntTy 32	(* 64BIT: FIXME *)
		      | cty AP.CCML = CU.BOGt
		      | cty AP.CCI64 = CU.BOGt	(* 64BIT: FIXME *)
		    val a' = lpvar a
		    val rcckind = if reentrant then REENTRANT_RCC else FAST_RCC
		    fun rcc args = let
			val al = map VAR args
			val (al,linkage) =
			    case f of
			      F.STRING linkage => (al, linkage)
			    | _  => (lpvar f :: al, "")
		    in  case ml_res_opt
			 of NONE =>
			    RCC (rcckind, linkage, c_proto, al, [(v, tagIntTy)], loop (e, c))
(* 64BIT: this code implements the fake 64-bit integers that are used on 32-bit targets *)
			  | SOME AP.CCI64 =>
			    let val (v1, v2) = (mkv (), mkv ())
			    in
			      RCC (rcckind, linkage, c_proto, al,
				   [(v1, boxIntTy 32), (v2, boxIntTy 32)],
				   recordNM([VAR v1, VAR v2],[boxIntTy 32, boxIntTy 32],
					    v, loop (e, c)))
			    end
			  | SOME rt => let
				val v' = mkv ()
				val res_cty = cty rt
			    in
				RCC (rcckind, linkage, c_proto, al, [(v', res_cty)],
				     PURE(primwrap res_cty, [VAR v'], v, CU.BOGt,
					  loop (e, c)))
			    end
		    end
		    val sel = if is_float_record a then selectFL else selectNM
		    fun build ([], rvl, _) = rcc (rev rvl)
		      | build (ft :: ftl, rvl, i) = let
			    val t = cty ft
			    val v = mkv ()
			in
			    sel (i, a', v, t, build (ftl, v :: rvl, i + 1))
			end
		in
		    case ml_args of
			[ft] => let
			    (* if there is precisely one arg, then it will not
			     * come packaged into a record *)
			    val t = cty ft
			    val v = mkv ()
			in
			    PURE (primunwrap t, [a'], v, t, rcc [v])
			end
		      | _ => build (ml_args, [], 0)
		end

	      | F.PRIMOP ((_,AP.RAW_CCALL _,_,_),_,_,_) => bug "bad raw_ccall"

	      | F.PRIMOP ((_,AP.RAW_RECORD _,_,_),[x as F.VAR _],v,e) =>
		(* code generated here should never be executed anyway,
		 * so we just fake it... *)
		(print "*** pro-forma raw-record\n";
		 newname (v, lpvar x); loop(e,c))

	      | F.PRIMOP(po as (_,p,lt,ts), ul, v, e) =>
		  let val ct =
			case (#3(LT.ltd_arrow(LT.lt_pinst (lt, ts))))
			 of [x] => CU.ctype x
			  | _ => bug "unexpected case in F.PRIMOP"
		      val vl = lpvars ul
		   in case map_primop p
		       of PKS i => let val _ = newname(v, tagInt 0)
				    in SETTER(i, vl, loop(e,c))
				   end
			| PKA i => ARITH(i, vl, v, ct, loop(e,c))
			| PKL i => LOOKER(i, vl, v, ct, loop(e,c))
			| PKP i => PURE(i, vl, v, ct, loop(e,c))
		  end

	      | F.BRANCH(po as (_,p,_,_), ul, e1, e2) =>
		  let val (hdr, F) = preventEta c
		      val kont = makmc(fn vl => APP(F, vl), rttys c)
		   in hdr(BRANCH(map_branch p, lpvars ul, mkv(),
				 loop(e1, kont), loop(e2, kont)))
		  end
	 end

	(* processing the top-level fundec *)
	val (fk, f, vts, be) = fdec
	val k = mkv()    (* top-level return continuation *)
	val kont = makmc (fn vs => APP(VAR k, vs), res_ctys f)
	val body = loop' M.empty (be, kont)

	val vl = k::(map #1 vts)
	val cl = CNTt::(map (CU.ctype o #2) vts)
     in (ESCAPE, f, vl, cl, bogus_header body) before cleanUp()
    end (* function convert *)

  end (* functor Convert *)