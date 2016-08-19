(*
 * WARNING: This file was automatically generated by MDLGen (v3.1)
 * from the machine description file "alpha/alpha.mdl".
 * DO NOT EDIT this file directly
 *)


signature ALPHAINSTR =
sig
   structure C : ALPHACELLS
   structure CB : CELLS_BASIS = CellsBasis
   structure T : MLTREE
   structure Constant: CONSTANT
   structure Region : REGION
      sharing Constant = T.Constant
      sharing Region = T.Region
   datatype ea =
     Direct of CellsBasis.cell
   | FDirect of CellsBasis.cell
   | Displace of {base:CellsBasis.cell, disp:T.labexp, mem:Region.region}
   datatype operand =
     REGop of CellsBasis.cell
   | IMMop of int
   | HILABop of T.labexp
   | LOLABop of T.labexp
   | LABop of T.labexp
   datatype branch =
     BR
   | BLBC
   | BEQ
   | BLT
   | BLE
   | BLBS
   | BNE
   | BGE
   | BGT
   datatype fbranch =
     FBEQ
   | FBLT
   | FBLE
   | FBNE
   | FBGE
   | FBGT
   datatype load =
     LDB
   | LDW
   | LDBU
   | LDWU
   | LDL
   | LDL_L
   | LDQ
   | LDQ_L
   | LDQ_U
   datatype store =
     STB
   | STW
   | STL
   | STQ
   | STQ_U
   datatype fload =
     LDF
   | LDG
   | LDS
   | LDT
   datatype fstore =
     STF
   | STG
   | STS
   | STT
   datatype operate =
     ADDL
   | ADDQ
   | CMPBGE
   | CMPEQ
   | CMPLE
   | CMPLT
   | CMPULE
   | CMPULT
   | SUBL
   | SUBQ
   | S4ADDL
   | S4ADDQ
   | S4SUBL
   | S4SUBQ
   | S8ADDL
   | S8ADDQ
   | S8SUBL
   | S8SUBQ
   | AND
   | BIC
   | BIS
   | EQV
   | ORNOT
   | XOR
   | EXTBL
   | EXTLH
   | EXTLL
   | EXTQH
   | EXTQL
   | EXTWH
   | EXTWL
   | INSBL
   | INSLH
   | INSLL
   | INSQH
   | INSQL
   | INSWH
   | INSWL
   | MSKBL
   | MSKLH
   | MSKLL
   | MSKQH
   | MSKQL
   | MSKWH
   | MSKWL
   | SLL
   | SRA
   | SRL
   | ZAP
   | ZAPNOT
   | MULL
   | MULQ
   | UMULH
   datatype cmove =
     CMOVEQ
   | CMOVLBC
   | CMOVLBS
   | CMOVGE
   | CMOVGT
   | CMOVLE
   | CMOVLT
   | CMOVNE
   datatype pseudo_op =
     DIVL
   | DIVLU
   | DIVQ
   | DIVQU
   | REML
   | REMLU
   | REMQ
   | REMQU
   datatype operateV =
     ADDLV
   | ADDQV
   | SUBLV
   | SUBQV
   | MULLV
   | MULQV
   datatype funary =
     CVTLQ
   | CVTQL
   | CVTQLSV
   | CVTQLV
   | CVTQS
   | CVTQSC
   | CVTQT
   | CVTQTC
   | CVTTS
   | CVTTSC
   | CVTST
   | CVTSTS
   | CVTTQ
   | CVTTQC
   datatype foperate =
     CPYS
   | CPYSE
   | CPYSN
   | MF_FPCR
   | MT_FPCR
   | CMPTEQ
   | CMPTLT
   | CMPTLE
   | CMPTUN
   | CMPTEQSU
   | CMPTLTSU
   | CMPTLESU
   | CMPTUNSU
   | ADDS
   | ADDT
   | DIVS
   | DIVT
   | MULS
   | MULT
   | SUBS
   | SUBT
   datatype fcmove =
     FCMOVEQ
   | FCMOVGE
   | FCMOVGT
   | FCMOVLE
   | FCMOVLT
   | FCMOVNE
   datatype foperateV =
     ADDSSUD
   | ADDSSU
   | ADDTSUD
   | ADDTSU
   | DIVSSUD
   | DIVSSU
   | DIVTSUD
   | DIVTSU
   | MULSSUD
   | MULSSU
   | MULTSUD
   | MULTSU
   | SUBSSUD
   | SUBSSU
   | SUBTSUD
   | SUBTSU
   datatype osf_user_palcode =
     BPT
   | BUGCHK
   | CALLSYS
   | GENTRAP
   | IMB
   | RDUNIQUE
   | WRUNIQUE
   type addressing_mode = CellsBasis.cell * operand
   datatype instr =
     LDA of {r:CellsBasis.cell, b:CellsBasis.cell, d:operand}
   | LDAH of {r:CellsBasis.cell, b:CellsBasis.cell, d:operand}
   | LOAD of {ldOp:load, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, mem:Region.region}
   | STORE of {stOp:store, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | FLOAD of {ldOp:fload, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | FSTORE of {stOp:fstore, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | JMPL of {r:CellsBasis.cell, b:CellsBasis.cell, d:int} * Label.label list
   | JSR of {r:CellsBasis.cell, b:CellsBasis.cell, d:int, defs:C.cellset, uses:C.cellset, 
        cutsTo:Label.label list, mem:Region.region}
   | BSR of {r:CellsBasis.cell, lab:Label.label, defs:C.cellset, uses:C.cellset, 
        cutsTo:Label.label list, mem:Region.region}
   | RET of {r:CellsBasis.cell, b:CellsBasis.cell, d:int}
   | BRANCH of {b:branch, r:CellsBasis.cell, lab:Label.label}
   | FBRANCH of {b:fbranch, f:CellsBasis.cell, lab:Label.label}
   | OPERATE of {oper:operate, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | OPERATEV of {oper:operateV, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | CMOVE of {oper:cmove, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | PSEUDOARITH of {oper:pseudo_op, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell, 
        tmps:C.cellset}
   | FUNARY of {oper:funary, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | FOPERATE of {oper:foperate, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | FOPERATEV of {oper:foperateV, fa:CellsBasis.cell, fb:CellsBasis.cell, 
        fc:CellsBasis.cell}
   | FCMOVE of {oper:fcmove, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | TRAPB
   | CALL_PAL of {code:osf_user_palcode, def:C.cellset, use:C.cellset}
   | SOURCE of {}
   | SINK of {}
   | PHI of {}
   and instruction =
     LIVE of {regs: C.cellset, spilled: C.cellset}
   | KILL of {regs: C.cellset, spilled: C.cellset}
   | COPY of {k: CellsBasis.cellkind, 
              sz: int,          (* in bits *)
              dst: CellsBasis.cell list,
              src: CellsBasis.cell list,
              tmp: ea option (* NONE if |dst| = {src| = 1 *)}
   | ANNOTATION of {i:instruction, a:Annotations.annotation}
   | INSTR of instr
   val lda : {r:CellsBasis.cell, b:CellsBasis.cell, d:operand} -> instruction
   val ldah : {r:CellsBasis.cell, b:CellsBasis.cell, d:operand} -> instruction
   val load : {ldOp:load, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
      mem:Region.region} -> instruction
   val store : {stOp:store, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
      mem:Region.region} -> instruction
   val fload : {ldOp:fload, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
      mem:Region.region} -> instruction
   val fstore : {stOp:fstore, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
      mem:Region.region} -> instruction
   val jmpl : {r:CellsBasis.cell, b:CellsBasis.cell, d:int} * Label.label list -> instruction
   val jsr : {r:CellsBasis.cell, b:CellsBasis.cell, d:int, defs:C.cellset, 
      uses:C.cellset, cutsTo:Label.label list, mem:Region.region} -> instruction
   val bsr : {r:CellsBasis.cell, lab:Label.label, defs:C.cellset, uses:C.cellset, 
      cutsTo:Label.label list, mem:Region.region} -> instruction
   val ret : {r:CellsBasis.cell, b:CellsBasis.cell, d:int} -> instruction
   val branch : {b:branch, r:CellsBasis.cell, lab:Label.label} -> instruction
   val fbranch : {b:fbranch, f:CellsBasis.cell, lab:Label.label} -> instruction
   val operate : {oper:operate, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell} -> instruction
   val operatev : {oper:operateV, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell} -> instruction
   val cmove : {oper:cmove, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell} -> instruction
   val pseudoarith : {oper:pseudo_op, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell, 
      tmps:C.cellset} -> instruction
   val funary : {oper:funary, fb:CellsBasis.cell, fc:CellsBasis.cell} -> instruction
   val foperate : {oper:foperate, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell} -> instruction
   val foperatev : {oper:foperateV, fa:CellsBasis.cell, fb:CellsBasis.cell, 
      fc:CellsBasis.cell} -> instruction
   val fcmove : {oper:fcmove, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell} -> instruction
   val trapb : instruction
   val call_pal : {code:osf_user_palcode, def:C.cellset, use:C.cellset} -> instruction
   val source : {} -> instruction
   val sink : {} -> instruction
   val phi : {} -> instruction
end

functor AlphaInstr(T: MLTREE
                  ) : ALPHAINSTR =
struct
   structure C = AlphaCells
   structure CB = CellsBasis
   structure T = T
   structure Region = T.Region
   structure Constant = T.Constant
   datatype ea =
     Direct of CellsBasis.cell
   | FDirect of CellsBasis.cell
   | Displace of {base:CellsBasis.cell, disp:T.labexp, mem:Region.region}
   datatype operand =
     REGop of CellsBasis.cell
   | IMMop of int
   | HILABop of T.labexp
   | LOLABop of T.labexp
   | LABop of T.labexp
   datatype branch =
     BR
   | BLBC
   | BEQ
   | BLT
   | BLE
   | BLBS
   | BNE
   | BGE
   | BGT
   datatype fbranch =
     FBEQ
   | FBLT
   | FBLE
   | FBNE
   | FBGE
   | FBGT
   datatype load =
     LDB
   | LDW
   | LDBU
   | LDWU
   | LDL
   | LDL_L
   | LDQ
   | LDQ_L
   | LDQ_U
   datatype store =
     STB
   | STW
   | STL
   | STQ
   | STQ_U
   datatype fload =
     LDF
   | LDG
   | LDS
   | LDT
   datatype fstore =
     STF
   | STG
   | STS
   | STT
   datatype operate =
     ADDL
   | ADDQ
   | CMPBGE
   | CMPEQ
   | CMPLE
   | CMPLT
   | CMPULE
   | CMPULT
   | SUBL
   | SUBQ
   | S4ADDL
   | S4ADDQ
   | S4SUBL
   | S4SUBQ
   | S8ADDL
   | S8ADDQ
   | S8SUBL
   | S8SUBQ
   | AND
   | BIC
   | BIS
   | EQV
   | ORNOT
   | XOR
   | EXTBL
   | EXTLH
   | EXTLL
   | EXTQH
   | EXTQL
   | EXTWH
   | EXTWL
   | INSBL
   | INSLH
   | INSLL
   | INSQH
   | INSQL
   | INSWH
   | INSWL
   | MSKBL
   | MSKLH
   | MSKLL
   | MSKQH
   | MSKQL
   | MSKWH
   | MSKWL
   | SLL
   | SRA
   | SRL
   | ZAP
   | ZAPNOT
   | MULL
   | MULQ
   | UMULH
   datatype cmove =
     CMOVEQ
   | CMOVLBC
   | CMOVLBS
   | CMOVGE
   | CMOVGT
   | CMOVLE
   | CMOVLT
   | CMOVNE
   datatype pseudo_op =
     DIVL
   | DIVLU
   | DIVQ
   | DIVQU
   | REML
   | REMLU
   | REMQ
   | REMQU
   datatype operateV =
     ADDLV
   | ADDQV
   | SUBLV
   | SUBQV
   | MULLV
   | MULQV
   datatype funary =
     CVTLQ
   | CVTQL
   | CVTQLSV
   | CVTQLV
   | CVTQS
   | CVTQSC
   | CVTQT
   | CVTQTC
   | CVTTS
   | CVTTSC
   | CVTST
   | CVTSTS
   | CVTTQ
   | CVTTQC
   datatype foperate =
     CPYS
   | CPYSE
   | CPYSN
   | MF_FPCR
   | MT_FPCR
   | CMPTEQ
   | CMPTLT
   | CMPTLE
   | CMPTUN
   | CMPTEQSU
   | CMPTLTSU
   | CMPTLESU
   | CMPTUNSU
   | ADDS
   | ADDT
   | DIVS
   | DIVT
   | MULS
   | MULT
   | SUBS
   | SUBT
   datatype fcmove =
     FCMOVEQ
   | FCMOVGE
   | FCMOVGT
   | FCMOVLE
   | FCMOVLT
   | FCMOVNE
   datatype foperateV =
     ADDSSUD
   | ADDSSU
   | ADDTSUD
   | ADDTSU
   | DIVSSUD
   | DIVSSU
   | DIVTSUD
   | DIVTSU
   | MULSSUD
   | MULSSU
   | MULTSUD
   | MULTSU
   | SUBSSUD
   | SUBSSU
   | SUBTSUD
   | SUBTSU
   datatype osf_user_palcode =
     BPT
   | BUGCHK
   | CALLSYS
   | GENTRAP
   | IMB
   | RDUNIQUE
   | WRUNIQUE
   type addressing_mode = CellsBasis.cell * operand
   datatype instr =
     LDA of {r:CellsBasis.cell, b:CellsBasis.cell, d:operand}
   | LDAH of {r:CellsBasis.cell, b:CellsBasis.cell, d:operand}
   | LOAD of {ldOp:load, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, mem:Region.region}
   | STORE of {stOp:store, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | FLOAD of {ldOp:fload, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | FSTORE of {stOp:fstore, r:CellsBasis.cell, b:CellsBasis.cell, d:operand, 
        mem:Region.region}
   | JMPL of {r:CellsBasis.cell, b:CellsBasis.cell, d:int} * Label.label list
   | JSR of {r:CellsBasis.cell, b:CellsBasis.cell, d:int, defs:C.cellset, uses:C.cellset, 
        cutsTo:Label.label list, mem:Region.region}
   | BSR of {r:CellsBasis.cell, lab:Label.label, defs:C.cellset, uses:C.cellset, 
        cutsTo:Label.label list, mem:Region.region}
   | RET of {r:CellsBasis.cell, b:CellsBasis.cell, d:int}
   | BRANCH of {b:branch, r:CellsBasis.cell, lab:Label.label}
   | FBRANCH of {b:fbranch, f:CellsBasis.cell, lab:Label.label}
   | OPERATE of {oper:operate, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | OPERATEV of {oper:operateV, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | CMOVE of {oper:cmove, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell}
   | PSEUDOARITH of {oper:pseudo_op, ra:CellsBasis.cell, rb:operand, rc:CellsBasis.cell, 
        tmps:C.cellset}
   | FUNARY of {oper:funary, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | FOPERATE of {oper:foperate, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | FOPERATEV of {oper:foperateV, fa:CellsBasis.cell, fb:CellsBasis.cell, 
        fc:CellsBasis.cell}
   | FCMOVE of {oper:fcmove, fa:CellsBasis.cell, fb:CellsBasis.cell, fc:CellsBasis.cell}
   | TRAPB
   | CALL_PAL of {code:osf_user_palcode, def:C.cellset, use:C.cellset}
   | SOURCE of {}
   | SINK of {}
   | PHI of {}
   and instruction =
     LIVE of {regs: C.cellset, spilled: C.cellset}
   | KILL of {regs: C.cellset, spilled: C.cellset}
   | COPY of {k: CellsBasis.cellkind, 
              sz: int,          (* in bits *)
              dst: CellsBasis.cell list,
              src: CellsBasis.cell list,
              tmp: ea option (* NONE if |dst| = {src| = 1 *)}
   | ANNOTATION of {i:instruction, a:Annotations.annotation}
   | INSTR of instr
   val lda = INSTR o LDA
   and ldah = INSTR o LDAH
   and load = INSTR o LOAD
   and store = INSTR o STORE
   and fload = INSTR o FLOAD
   and fstore = INSTR o FSTORE
   and jmpl = INSTR o JMPL
   and jsr = INSTR o JSR
   and bsr = INSTR o BSR
   and ret = INSTR o RET
   and branch = INSTR o BRANCH
   and fbranch = INSTR o FBRANCH
   and operate = INSTR o OPERATE
   and operatev = INSTR o OPERATEV
   and cmove = INSTR o CMOVE
   and pseudoarith = INSTR o PSEUDOARITH
   and funary = INSTR o FUNARY
   and foperate = INSTR o FOPERATE
   and foperatev = INSTR o FOPERATEV
   and fcmove = INSTR o FCMOVE
   and trapb = INSTR TRAPB
   and call_pal = INSTR o CALL_PAL
   and source = INSTR o SOURCE
   and sink = INSTR o SINK
   and phi = INSTR o PHI
end

