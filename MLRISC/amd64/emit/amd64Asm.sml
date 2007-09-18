(*
 * WARNING: This file was automatically generated by MDLGen (v3.0)
 * from the machine description file "amd64/amd64.mdl".
 * DO NOT EDIT this file directly
 *)


functor AMD64AsmEmitter(structure S : INSTRUCTION_STREAM
                        structure Instr : AMD64INSTR
                           where T = S.P.T
                        structure Shuffle : AMD64SHUFFLE
                           where I = Instr
                        structure MLTreeEval : MLTREE_EVAL
                           where T = Instr.T
                       ) : INSTRUCTION_EMITTER =
struct
   structure I  = Instr
   structure C  = I.C
   structure T  = I.T
   structure S  = S
   structure P  = S.P
   structure Constant = I.Constant
   
   open AsmFlags
   
   fun error msg = MLRiscErrorMsg.error("AMD64AsmEmitter",msg)
   
   fun makeStream formatAnnotations =
   let val stream = !AsmStream.asmOutStream
       fun emit' s = TextIO.output(stream,s)
       val newline = ref true
       val tabs = ref 0
       fun tabbing 0 = ()
         | tabbing n = (emit' "\t"; tabbing(n-1))
       fun emit s = (tabbing(!tabs); tabs := 0; newline := false; emit' s)
       fun nl() = (tabs := 0; if !newline then () else (newline := true; emit' "\n"))
       fun comma() = emit ","
       fun tab() = tabs := 1
       fun indent() = tabs := 2
       fun ms n = let val s = Int.toString n
                  in  if n<0 then "-"^String.substring(s,1,size s-1)
                      else s
                  end
       fun emit_label lab = emit(P.Client.AsmPseudoOps.lexpToString(T.LABEL lab))
       fun emit_labexp le = emit(P.Client.AsmPseudoOps.lexpToString (T.LABEXP le))
       fun emit_const c = emit(Constant.toString c)
       fun emit_int i = emit(ms i)
       fun paren f = (emit "("; f(); emit ")")
       fun defineLabel lab = emit(P.Client.AsmPseudoOps.defineLabel lab^"\n")
       fun entryLabel lab = defineLabel lab
       fun comment msg = (tab(); emit("/* " ^ msg ^ " */"); nl())
       fun annotation a = comment(Annotations.toString a)
       fun getAnnotations() = error "getAnnotations"
       fun doNothing _ = ()
       fun fail _ = raise Fail "AsmEmitter"
       fun emit_region mem = comment(I.Region.toString mem)
       val emit_region = 
          if !show_region then emit_region else doNothing
       fun pseudoOp pOp = (emit(P.toString pOp); emit "\n")
       fun init size = (comment("Code Size = " ^ ms size); nl())
       val emitCellInfo = AsmFormatUtil.reginfo
                                (emit,formatAnnotations)
       fun emitCell r = (emit(CellsBasis.toString r); emitCellInfo r)
       fun emit_cellset(title,cellset) =
         (nl(); comment(title^CellsBasis.CellSet.toString cellset))
       val emit_cellset = 
         if !show_cellset then emit_cellset else doNothing
       fun emit_defs cellset = emit_cellset("defs: ",cellset)
       fun emit_uses cellset = emit_cellset("uses: ",cellset)
       val emit_cutsTo = 
         if !show_cutsTo then AsmFormatUtil.emit_cutsTo emit
         else doNothing
       fun emitter instr =
       let
   fun asm_cond (I.EQ) = "e"
     | asm_cond (I.NE) = "ne"
     | asm_cond (I.LT) = "l"
     | asm_cond (I.LE) = "le"
     | asm_cond (I.GT) = "g"
     | asm_cond (I.GE) = "ge"
     | asm_cond (I.B) = "b"
     | asm_cond (I.BE) = "be"
     | asm_cond (I.A) = "a"
     | asm_cond (I.AE) = "ae"
     | asm_cond (I.C) = "c"
     | asm_cond (I.NC) = "nc"
     | asm_cond (I.P) = "p"
     | asm_cond (I.NP) = "np"
     | asm_cond (I.O) = "o"
     | asm_cond (I.NO) = "no"
   and emit_cond x = emit (asm_cond x)
   and asm_binaryOp (I.ADDQ) = "addq"
     | asm_binaryOp (I.SUBQ) = "subq"
     | asm_binaryOp (I.ANDQ) = "andq"
     | asm_binaryOp (I.ORQ) = "orq"
     | asm_binaryOp (I.XORQ) = "xorq"
     | asm_binaryOp (I.SHLQ) = "shlq"
     | asm_binaryOp (I.SARQ) = "sarq"
     | asm_binaryOp (I.SHRQ) = "shrq"
     | asm_binaryOp (I.MULQ) = "mulq"
     | asm_binaryOp (I.IMULQ) = "imulq"
     | asm_binaryOp (I.ADCQ) = "adcq"
     | asm_binaryOp (I.SBBQ) = "sbbq"
     | asm_binaryOp (I.ADDL) = "addl"
     | asm_binaryOp (I.SUBL) = "subl"
     | asm_binaryOp (I.ANDL) = "andl"
     | asm_binaryOp (I.ORL) = "orl"
     | asm_binaryOp (I.XORL) = "xorl"
     | asm_binaryOp (I.SHLL) = "shll"
     | asm_binaryOp (I.SARL) = "sarl"
     | asm_binaryOp (I.SHRL) = "shrl"
     | asm_binaryOp (I.MULL) = "mull"
     | asm_binaryOp (I.IMULL) = "imull"
     | asm_binaryOp (I.ADCL) = "adcl"
     | asm_binaryOp (I.SBBL) = "sbbl"
     | asm_binaryOp (I.ADDW) = "addw"
     | asm_binaryOp (I.SUBW) = "subw"
     | asm_binaryOp (I.ANDW) = "andw"
     | asm_binaryOp (I.ORW) = "orw"
     | asm_binaryOp (I.XORW) = "xorw"
     | asm_binaryOp (I.SHLW) = "shlw"
     | asm_binaryOp (I.SARW) = "sarw"
     | asm_binaryOp (I.SHRW) = "shrw"
     | asm_binaryOp (I.MULW) = "mulw"
     | asm_binaryOp (I.IMULW) = "imulw"
     | asm_binaryOp (I.ADDB) = "addb"
     | asm_binaryOp (I.SUBB) = "subb"
     | asm_binaryOp (I.ANDB) = "andb"
     | asm_binaryOp (I.ORB) = "orb"
     | asm_binaryOp (I.XORB) = "xorb"
     | asm_binaryOp (I.SHLB) = "shlb"
     | asm_binaryOp (I.SARB) = "sarb"
     | asm_binaryOp (I.SHRB) = "shrb"
     | asm_binaryOp (I.MULB) = "mulb"
     | asm_binaryOp (I.IMULB) = "imulb"
     | asm_binaryOp (I.BTSW) = "btsw"
     | asm_binaryOp (I.BTCW) = "btcw"
     | asm_binaryOp (I.BTRW) = "btrw"
     | asm_binaryOp (I.BTSL) = "btsl"
     | asm_binaryOp (I.BTCL) = "btcl"
     | asm_binaryOp (I.BTRL) = "btrl"
     | asm_binaryOp (I.ROLW) = "rolw"
     | asm_binaryOp (I.RORW) = "rorw"
     | asm_binaryOp (I.ROLL) = "roll"
     | asm_binaryOp (I.RORL) = "rorl"
     | asm_binaryOp (I.XCHGB) = "xchgb"
     | asm_binaryOp (I.XCHGW) = "xchgw"
     | asm_binaryOp (I.XCHGL) = "xchgl"
     | asm_binaryOp (I.LOCK_ADCW) = "lock\n\tadcw"
     | asm_binaryOp (I.LOCK_ADCL) = "lock\n\tadcl"
     | asm_binaryOp (I.LOCK_ADDW) = "lock\n\taddw"
     | asm_binaryOp (I.LOCK_ADDL) = "lock\n\taddl"
     | asm_binaryOp (I.LOCK_ANDW) = "lock\n\tandw"
     | asm_binaryOp (I.LOCK_ANDL) = "lock\n\tandl"
     | asm_binaryOp (I.LOCK_BTSW) = "lock\n\tbtsw"
     | asm_binaryOp (I.LOCK_BTSL) = "lock\n\tbtsl"
     | asm_binaryOp (I.LOCK_BTRW) = "lock\n\tbtrw"
     | asm_binaryOp (I.LOCK_BTRL) = "lock\n\tbtrl"
     | asm_binaryOp (I.LOCK_BTCW) = "lock\n\tbtcw"
     | asm_binaryOp (I.LOCK_BTCL) = "lock\n\tbtcl"
     | asm_binaryOp (I.LOCK_ORW) = "lock\n\torw"
     | asm_binaryOp (I.LOCK_ORL) = "lock\n\torl"
     | asm_binaryOp (I.LOCK_SBBW) = "lock\n\tsbbw"
     | asm_binaryOp (I.LOCK_SBBL) = "lock\n\tsbbl"
     | asm_binaryOp (I.LOCK_SUBW) = "lock\n\tsubw"
     | asm_binaryOp (I.LOCK_SUBL) = "lock\n\tsubl"
     | asm_binaryOp (I.LOCK_XORW) = "lock\n\txorw"
     | asm_binaryOp (I.LOCK_XORL) = "lock\n\txorl"
     | asm_binaryOp (I.LOCK_XADDB) = "lock\n\txaddb"
     | asm_binaryOp (I.LOCK_XADDW) = "lock\n\txaddw"
     | asm_binaryOp (I.LOCK_XADDL) = "lock\n\txaddl"
   and emit_binaryOp x = emit (asm_binaryOp x)
   and asm_multDivOp (I.IMULL1) = "imull"
     | asm_multDivOp (I.MULL1) = "mull"
     | asm_multDivOp (I.IDIVL1) = "idivl"
     | asm_multDivOp (I.DIVL1) = "divl"
     | asm_multDivOp (I.IMULQ1) = "imulq"
     | asm_multDivOp (I.MULQ1) = "mulq"
     | asm_multDivOp (I.IDIVQ1) = "idivq"
     | asm_multDivOp (I.DIVQ1) = "divq"
   and emit_multDivOp x = emit (asm_multDivOp x)
   and asm_unaryOp (I.DECQ) = "decq"
     | asm_unaryOp (I.INCQ) = "incq"
     | asm_unaryOp (I.NEGQ) = "negq"
     | asm_unaryOp (I.NOTQ) = "notq"
     | asm_unaryOp (I.DECL) = "decl"
     | asm_unaryOp (I.INCL) = "incl"
     | asm_unaryOp (I.NEGL) = "negl"
     | asm_unaryOp (I.NOTL) = "notl"
     | asm_unaryOp (I.DECW) = "decw"
     | asm_unaryOp (I.INCW) = "incw"
     | asm_unaryOp (I.NEGW) = "negw"
     | asm_unaryOp (I.NOTW) = "notw"
     | asm_unaryOp (I.DECB) = "decb"
     | asm_unaryOp (I.INCB) = "incb"
     | asm_unaryOp (I.NEGB) = "negb"
     | asm_unaryOp (I.NOTB) = "notb"
     | asm_unaryOp (I.LOCK_DECQ) = "lock\n\tdecq"
     | asm_unaryOp (I.LOCK_INCQ) = "lock\n\tincq"
     | asm_unaryOp (I.LOCK_NEGQ) = "lock\n\tnegq"
     | asm_unaryOp (I.LOCK_NOTQ) = "lock\n\tnotq"
   and emit_unaryOp x = emit (asm_unaryOp x)
   and asm_shiftOp (I.SHLDL) = "shldl"
     | asm_shiftOp (I.SHRDL) = "shrdl"
   and emit_shiftOp x = emit (asm_shiftOp x)
   and asm_bitOp (I.BTW) = "btw"
     | asm_bitOp (I.BTL) = "btl"
     | asm_bitOp (I.BTQ) = "btq"
     | asm_bitOp (I.LOCK_BTW) = "lock\n\tbtw"
     | asm_bitOp (I.LOCK_BTL) = "lock\n\tbtl"
   and emit_bitOp x = emit (asm_bitOp x)
   and asm_move (I.MOVQ) = "movq"
     | asm_move (I.MOVL) = "movl"
     | asm_move (I.MOVB) = "movb"
     | asm_move (I.MOVW) = "movw"
     | asm_move (I.MOVABSQ) = "movabsq"
     | asm_move (I.MOVSWQ) = "movswq"
     | asm_move (I.MOVZWQ) = "movzwq"
     | asm_move (I.MOVSWL) = "movswl"
     | asm_move (I.MOVZWL) = "movzwl"
     | asm_move (I.MOVSBQ) = "movsbq"
     | asm_move (I.MOVZBQ) = "movzbq"
     | asm_move (I.MOVSBL) = "movsbl"
     | asm_move (I.MOVZBL) = "movzbl"
     | asm_move (I.MOVSLQ) = "movslq"
   and emit_move x = emit (asm_move x)
   and asm_fbin_op (I.ADDSS) = "addss"
     | asm_fbin_op (I.ADDSD) = "addsd"
     | asm_fbin_op (I.SUBSS) = "subss"
     | asm_fbin_op (I.SUBSD) = "subsd"
     | asm_fbin_op (I.MULSS) = "mulss"
     | asm_fbin_op (I.MULSD) = "mulsd"
     | asm_fbin_op (I.DIVSS) = "divss"
     | asm_fbin_op (I.DIVSD) = "divsd"
   and emit_fbin_op x = emit (asm_fbin_op x)
   and asm_fcom_op (I.COMISS) = "comiss"
     | asm_fcom_op (I.COMISD) = "comisd"
     | asm_fcom_op (I.UCOMISS) = "ucomiss"
     | asm_fcom_op (I.UCOMISD) = "ucomisd"
   and emit_fcom_op x = emit (asm_fcom_op x)
   and asm_fmove_op (I.MOVSS) = "movss"
     | asm_fmove_op (I.MOVSD) = "movsd"
     | asm_fmove_op (I.CVTSS2SD) = "cvtss2sd"
     | asm_fmove_op (I.CVTSD2SS) = "cvtsd2ss"
     | asm_fmove_op (I.CVTSS2SI) = "cvtss2si"
     | asm_fmove_op (I.CVTSS2SIQ) = "cvtss2siq"
     | asm_fmove_op (I.CVTSD2SI) = "cvtsd2si"
     | asm_fmove_op (I.CVTSD2SIQ) = "cvtsd2siq"
     | asm_fmove_op (I.CVTSI2SS) = "cvtsi2ss"
     | asm_fmove_op (I.CVTSI2SSQ) = "cvtsi2ssq"
     | asm_fmove_op (I.CVTSI2SD) = "cvtsi2sd"
     | asm_fmove_op (I.CVTSI2SDQ) = "cvtsi2sdq"
   and emit_fmove_op x = emit (asm_fmove_op x)
   and asm_fsize (I.FP32) = "s"
     | asm_fsize (I.FP64) = "l"
   and emit_fsize x = emit (asm_fsize x)
   and asm_isize (I.I8) = "8"
     | asm_isize (I.I16) = "16"
     | asm_isize (I.I32) = "32"
     | asm_isize (I.I64) = "64"
   and emit_isize x = emit (asm_isize x)

(*#line 472.7 "amd64/amd64.mdl"*)
   fun emitInt32 i = 
       let 
(*#line 472.29 "amd64/amd64.mdl"*)
           val s = Int32.toString i

(*#line 473.10 "amd64/amd64.mdl"*)
           val s = (if (i >= 0)
                  then s
                  else ("-" ^ (String.substring (s, 1, (size s) - 1))))
       in emit s
       end

(*#line 478.7 "amd64/amd64.mdl"*)
   val {low=SToffset, ...} = C.cellRange CellsBasis.FP

(*#line 480.7 "amd64/amd64.mdl"*)
   fun emitScale 0 = emit "1"
     | emitScale 1 = emit "2"
     | emitScale 2 = emit "4"
     | emitScale 3 = emit "8"
     | emitScale _ = error "emitScale"
   and eImmed (I.Immed i) = emitInt32 i
     | eImmed (I.ImmedLabel lexp) = emit_labexp lexp
     | eImmed _ = error "eImmed"
   and emit_operand opn = 
       (case opn of
         I.Immed i => 
         ( emit "$"; 
           emitInt32 i )
       | I.ImmedLabel lexp => 
         ( emit "$"; 
           emit_labexp lexp )
       | I.LabelEA le => emit_labexp le
       | I.Relative _ => error "emit_operand"
       | I.Direct(ty, r) => emit (CellsBasis.toStringWithSize (r, ty))
       | I.FDirect f => emit (CellsBasis.toString f)
       | I.Displace{base, disp, mem, ...} => 
         ( emit_disp disp; 
           emit "("; 
           emitCell base; 
           emit ")"; 
           emit_region mem )
       | I.Indexed{base, index, scale, disp, mem, ...} => 
         ( emit_disp disp; 
           emit "("; 
           
           (case base of
             NONE => ()
           | SOME base => emitCell base
           ); 
           comma (); 
           emitCell index; 
           comma (); 
           emitScale scale; 
           emit ")"; 
           emit_region mem )
       )
   and emit_operand8 (I.Direct(_, r)) = emit (CellsBasis.toStringWithSize (r, 
          8))
     | emit_operand8 opn = emit_operand opn
   and emit_cell (r, sz) = emit (CellsBasis.toStringWithSize (r, sz))
   and emit_disp (I.Immed 0) = ()
     | emit_disp (I.Immed i) = emitInt32 i
     | emit_disp (I.ImmedLabel lexp) = emit_labexp lexp
     | emit_disp _ = error "emit_disp"

(*#line 524.7 "amd64/amd64.mdl"*)
   fun stupidGas (I.ImmedLabel lexp) = emit_labexp lexp
     | stupidGas opnd = 
       ( emit "*"; 
         emit_operand opnd )

(*#line 528.7 "amd64/amd64.mdl"*)
   fun isMemOpnd (I.FDirect f) = true
     | isMemOpnd (I.LabelEA _) = true
     | isMemOpnd (I.Displace _) = true
     | isMemOpnd (I.Indexed _) = true
     | isMemOpnd _ = false

(*#line 533.7 "amd64/amd64.mdl"*)
   fun chop fbinOp = 
       let 
(*#line 534.15 "amd64/amd64.mdl"*)
           val n = size fbinOp
       in 
          (case Char.toLower (String.sub (fbinOp, n - 1)) of
            (#"s" | #"l") => String.substring (fbinOp, 0, n - 1)
          | _ => fbinOp
          )
       end

(*#line 540.7 "amd64/amd64.mdl"*)
   val emit_dst = emit_operand

(*#line 541.7 "amd64/amd64.mdl"*)
   val emit_src = emit_operand

(*#line 542.7 "amd64/amd64.mdl"*)
   val emit_opnd = emit_operand

(*#line 543.7 "amd64/amd64.mdl"*)
   val emit_opnd8 = emit_operand8

(*#line 544.7 "amd64/amd64.mdl"*)
   val emit_rsrc = emit_operand

(*#line 545.7 "amd64/amd64.mdl"*)
   val emit_lsrc = emit_operand

(*#line 546.7 "amd64/amd64.mdl"*)
   val emit_addr = emit_operand

(*#line 547.7 "amd64/amd64.mdl"*)
   val emit_src1 = emit_operand

(*#line 548.7 "amd64/amd64.mdl"*)
   val emit_ea = emit_operand

(*#line 549.7 "amd64/amd64.mdl"*)
   val emit_count = emit_operand
   fun emitInstr' instr = 
       (case instr of
         I.NOP => emit "nop"
       | I.JMP(operand, list) => 
         ( emit "jmp\t"; 
           stupidGas operand )
       | I.JCC{cond, opnd} => 
         ( emit "j"; 
           emit_cond cond; 
           emit "\t"; 
           stupidGas opnd )
       | I.CALL{opnd, defs, uses, return, cutsTo, mem, pops} => 
         ( emit "call\t"; 
           stupidGas opnd; 
           emit_region mem; 
           emit_defs defs; 
           emit_uses uses; 
           emit_cellset ("return", return); 
           emit_cutsTo cutsTo )
       | I.CALLQ{opnd, defs, uses, return, cutsTo, mem, pops} => 
         ( emit "call\t"; 
           stupidGas opnd; 
           emit_region mem; 
           emit_defs defs; 
           emit_uses uses; 
           emit_cellset ("return", return); 
           emit_cutsTo cutsTo )
       | I.ENTER{src1, src2} => 
         ( emit "enter\t"; 
           emit_operand src1; 
           emit ", "; 
           emit_operand src2 )
       | I.LEAVE => emit "leave"
       | I.RET option => 
         ( emit "ret"; 
           
           (case option of
             NONE => ()
           | SOME e => 
             ( emit "\t"; 
               emit_operand e )
           ))
       | I.MOVE{mvOp, src, dst} => 
         ( emit_move mvOp; 
           emit "\t"; 
           emit_src src; 
           emit ", "; 
           emit_dst dst )
       | I.LEAL{r32, addr} => 
         ( emit "leal\t"; 
           emit_addr addr; 
           emit ", "; 
           emit_cell (r32, 32))
       | I.LEAQ{r64, addr} => 
         ( emit "leaq\t"; 
           emit_addr addr; 
           emit ", "; 
           emit_cell (r64, 64))
       | I.CMPQ{lsrc, rsrc} => 
         ( emit "cmpq\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.CMPL{lsrc, rsrc} => 
         ( emit "cmpl\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.CMPW{lsrc, rsrc} => 
         ( emit "cmpb\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.CMPB{lsrc, rsrc} => 
         ( emit "cmpb\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.TESTQ{lsrc, rsrc} => 
         ( emit "testq\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.TESTL{lsrc, rsrc} => 
         ( emit "testl\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.TESTW{lsrc, rsrc} => 
         ( emit "testw\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.TESTB{lsrc, rsrc} => 
         ( emit "testb\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.BITOP{bitOp, lsrc, rsrc} => 
         ( emit_bitOp bitOp; 
           emit "\t"; 
           emit_rsrc rsrc; 
           emit ", "; 
           emit_lsrc lsrc )
       | I.BINARY{binOp, src, dst} => 
         (case (src, binOp) of
           (I.Direct _, 
           ( I.SARQ |
           I.SHRQ |
           I.SHLQ |
           I.SARL |
           I.SHRL |
           I.SHLL |
           I.SARW |
           I.SHRW |
           I.SHLW |
           I.SARB |
           I.SHRB |
           I.SHLB )) => 
           ( emit_binaryOp binOp; 
             emit "\t%cl, "; 
             emit_dst dst )
         | _ => 
           ( emit_binaryOp binOp; 
             emit "\t"; 
             emit_src src; 
             emit ", "; 
             emit_dst dst )
         )
       | I.SHIFT{shiftOp, src, dst, count} => 
         (case count of
           I.Direct(ty, ecx) => 
           ( emit_shiftOp shiftOp; 
             emit "\t"; 
             emit_src src; 
             emit ", "; 
             emit_dst dst )
         | _ => 
           ( emit_shiftOp shiftOp; 
             emit "\t"; 
             emit_src src; 
             emit ", "; 
             emit_count count; 
             emit ", "; 
             emit_dst dst )
         )
       | I.CMPXCHG{lock, sz, src, dst} => 
         ( (if lock
              then (emit "lock\n\t")
              else ()); 
           emit "cmpxchg"; 
           
           (case sz of
             I.I8 => emit "b"
           | I.I16 => emit "w"
           | I.I32 => emit "l"
           | I.I64 => emit "q"
           ); 
           
           ( emit "\t"; 
             emit_src src; 
             emit ", "; 
             emit_dst dst ) )
       | I.MULTDIV{multDivOp, src} => 
         ( emit_multDivOp multDivOp; 
           emit "\t"; 
           emit_src src )
       | I.MUL3{dst, src2, src1} => 
         ( emit "imull\t$"; 
           emitInt32 src2; 
           emit ", "; 
           emit_src1 src1; 
           emit ", "; 
           emit_cell (dst, 32))
       | I.MULQ3{dst, src2, src1} => 
         ( emit "imulq\t$"; 
           emitInt32 src2; 
           emit ", "; 
           emit_src1 src1; 
           emit ", "; 
           emit_cell (dst, 64))
       | I.UNARY{unOp, opnd} => 
         ( emit_unaryOp unOp; 
           emit "\t"; 
           emit_opnd opnd )
       | I.SET{cond, opnd} => 
         ( emit "set"; 
           emit_cond cond; 
           emit "\t"; 
           emit_opnd8 opnd )
       | I.CMOV{cond, src, dst} => 
         ( emit "cmov"; 
           emit_cond cond; 
           emit "\t"; 
           emit_src src; 
           emit ", "; 
           emitCell dst )
       | I.CMOVQ{cond, src, dst} => 
         ( emit "cmov"; 
           emit_cond cond; 
           emit "\t"; 
           emit_src src; 
           emit ", "; 
           emitCell dst )
       | I.PUSHQ operand => 
         ( emit "pushq\t"; 
           emit_operand operand )
       | I.PUSHL operand => 
         ( emit "pushl\t"; 
           emit_operand operand )
       | I.PUSHW operand => 
         ( emit "pushw\t"; 
           emit_operand operand )
       | I.PUSHB operand => 
         ( emit "pushb\t"; 
           emit_operand operand )
       | I.PUSHFD => emit "pushfd"
       | I.POPFD => emit "popfd"
       | I.POP operand => 
         ( emit "popq\t"; 
           emit_operand operand )
       | I.CDQ => emit "cdq"
       | I.INTO => emit "int $4"
       | I.FMOVE{fmvOp, dst, src} => 
         ( emit_fmove_op fmvOp; 
           emit "\t "; 
           emit_src src; 
           emit ", "; 
           emit_dst dst )
       | I.FBINOP{binOp, dst, src} => 
         ( emit_fbin_op binOp; 
           emit "\t "; 
           emitCell src; 
           emit ", "; 
           emitCell dst )
       | I.FCOM{comOp, dst, src} => 
         ( emit_fcom_op comOp; 
           emit "\t "; 
           emit_src src; 
           emit ", "; 
           emitCell dst )
       | I.FSQRTS{dst, src} => 
         ( emit "sqrtss\t "; 
           emit_src src; 
           emit ", "; 
           emit_dst dst )
       | I.FSQRTD{dst, src} => 
         ( emit "sqrtsd\t "; 
           emit_src src; 
           emit ", "; 
           emit_dst dst )
       | I.SAHF => emit "sahf"
       | I.LAHF => emit "lahf"
       | I.SOURCE{} => emit "source"
       | I.SINK{} => emit "sink"
       | I.PHI{} => emit "phi"
       )
      in  tab(); emitInstr' instr; nl()
      end (* emitter *)
      and emitInstrIndented i = (indent(); emitInstr i; nl())
      and emitInstrs instrs =
           app (if !indent_copies then emitInstrIndented
                else emitInstr) instrs
   
      and emitInstr(I.ANNOTATION{i,a}) =
           ( comment(Annotations.toString a);
              nl();
              emitInstr i )
        | emitInstr(I.LIVE{regs, spilled})  = 
            comment("live= " ^ CellsBasis.CellSet.toString regs ^
                    "spilled= " ^ CellsBasis.CellSet.toString spilled)
        | emitInstr(I.KILL{regs, spilled})  = 
            comment("killed:: " ^ CellsBasis.CellSet.toString regs ^
                    "spilled:: " ^ CellsBasis.CellSet.toString spilled)
        | emitInstr(I.INSTR i) = emitter i
        | emitInstr(I.COPY{k=CellsBasis.GP, sz, src, dst, tmp}) =
           emitInstrs(Shuffle.shuffle{tmp=tmp, src=src, dst=dst})
        | emitInstr(I.COPY{k=CellsBasis.FP, sz, src, dst, tmp}) =
           emitInstrs(Shuffle.shufflefp{tmp=tmp, src=src, dst=dst})
        | emitInstr _ = error "emitInstr"
   
   in  S.STREAM{beginCluster=init,
                pseudoOp=pseudoOp,
                emit=emitInstr,
                endCluster=fail,
                defineLabel=defineLabel,
                entryLabel=entryLabel,
                comment=comment,
                exitBlock=doNothing,
                annotation=annotation,
                getAnnotations=getAnnotations
               }
   end
end

