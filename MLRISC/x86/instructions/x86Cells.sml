(*
 * WARNING: This file was automatically generated by MDLGen (v3.0)
 * from the machine description file "x86/x86.mdl".
 * DO NOT EDIT this file directly
 *)


signature X86CELLS =
sig
   include CELLS
   val EFLAGS : CellsBasis.cellkind
   val FFLAGS : CellsBasis.cellkind
   val CELLSET : CellsBasis.cellkind
   val showGP : CellsBasis.register_id -> string
   val showFP : CellsBasis.register_id -> string
   val showCC : CellsBasis.register_id -> string
   val showEFLAGS : CellsBasis.register_id -> string
   val showFFLAGS : CellsBasis.register_id -> string
   val showMEM : CellsBasis.register_id -> string
   val showCTRL : CellsBasis.register_id -> string
   val showCELLSET : CellsBasis.register_id -> string
   val showGPWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showFPWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showCCWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showEFLAGSWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showFFLAGSWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showMEMWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showCTRLWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val showCELLSETWithSize : CellsBasis.register_id * CellsBasis.sz -> string
   val eax : CellsBasis.cell
   val ecx : CellsBasis.cell
   val edx : CellsBasis.cell
   val ebx : CellsBasis.cell
   val esp : CellsBasis.cell
   val ebp : CellsBasis.cell
   val esi : CellsBasis.cell
   val edi : CellsBasis.cell
   val ST : int -> CellsBasis.cell
   val ST0 : CellsBasis.cell
   val eflags : CellsBasis.cell
   val addGP : CellsBasis.cell * cellset -> cellset
   val addFP : CellsBasis.cell * cellset -> cellset
   val addCC : CellsBasis.cell * cellset -> cellset
   val addEFLAGS : CellsBasis.cell * cellset -> cellset
   val addFFLAGS : CellsBasis.cell * cellset -> cellset
   val addMEM : CellsBasis.cell * cellset -> cellset
   val addCTRL : CellsBasis.cell * cellset -> cellset
   val addCELLSET : CellsBasis.cell * cellset -> cellset
end

structure X86Cells : X86CELLS =
struct
   exception X86Cells
   fun error msg = MLRiscErrorMsg.error("X86Cells",msg)
   open CellsBasis
   fun showGPWithSize (r, ty) = (fn (0, 8) => "%al"
                                  | (0, 16) => "%ax"
                                  | (0, 32) => "%eax"
                                  | (1, 8) => "%cl"
                                  | (1, 16) => "%cx"
                                  | (1, 32) => "%ecx"
                                  | (2, 8) => "%dl"
                                  | (2, 16) => "%dx"
                                  | (2, 32) => "%edx"
                                  | (3, 8) => "%bl"
                                  | (3, 16) => "%bx"
                                  | (3, 32) => "%ebx"
                                  | (4, 16) => "%sp"
                                  | (4, 32) => "%esp"
                                  | (5, 16) => "%bp"
                                  | (5, 32) => "%ebp"
                                  | (6, 16) => "%si"
                                  | (6, 32) => "%esi"
                                  | (7, 16) => "%di"
                                  | (7, 32) => "%edi"
                                  | (r, _) => "%" ^ (Int.toString r)
                                ) (r, ty)
   and showFPWithSize (r, ty) = (fn (f, _) => (if (f < 8)
                                       then (("%st(" ^ (Int.toString f)) ^ ")")
                                       else ("%f" ^ (Int.toString f)))
                                ) (r, ty)
   and showCCWithSize (r, ty) = (fn _ => "cc"
                                ) (r, ty)
   and showEFLAGSWithSize (r, ty) = (fn _ => "$eflags"
                                    ) (r, ty)
   and showFFLAGSWithSize (r, ty) = (fn _ => "$fflags"
                                    ) (r, ty)
   and showMEMWithSize (r, ty) = (fn _ => "mem"
                                 ) (r, ty)
   and showCTRLWithSize (r, ty) = (fn _ => "ctrl"
                                  ) (r, ty)
   and showCELLSETWithSize (r, ty) = (fn _ => "CELLSET"
                                     ) (r, ty)
   fun showGP r = showGPWithSize (r, 32)
   fun showFP r = showFPWithSize (r, 64)
   fun showCC r = showCCWithSize (r, 32)
   fun showEFLAGS r = showEFLAGSWithSize (r, 32)
   fun showFFLAGS r = showFFLAGSWithSize (r, 32)
   fun showMEM r = showMEMWithSize (r, 8)
   fun showCTRL r = showCTRLWithSize (r, 0)
   fun showCELLSET r = showCELLSETWithSize (r, 0)
   val EFLAGS = CellsBasis.newCellKind {name="EFLAGS", nickname="eflags"}
   and FFLAGS = CellsBasis.newCellKind {name="FFLAGS", nickname="fflags"}
   and CELLSET = CellsBasis.newCellKind {name="CELLSET", nickname="cellset"}
   structure MyCells = Cells
      (exception Cells = X86Cells
       val firstPseudo = 256
       val desc_GP = CellsBasis.DESC {low=0, high=31, kind=CellsBasis.GP, defaultValues=[], 
              zeroReg=NONE, toString=showGP, toStringWithSize=showGPWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_FP = CellsBasis.DESC {low=32, high=63, kind=CellsBasis.FP, 
              defaultValues=[], zeroReg=NONE, toString=showFP, toStringWithSize=showFPWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_EFLAGS = CellsBasis.DESC {low=64, high=64, kind=EFLAGS, defaultValues=[], 
              zeroReg=NONE, toString=showEFLAGS, toStringWithSize=showEFLAGSWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_FFLAGS = CellsBasis.DESC {low=65, high=65, kind=FFLAGS, defaultValues=[], 
              zeroReg=NONE, toString=showFFLAGS, toStringWithSize=showFFLAGSWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_MEM = CellsBasis.DESC {low=66, high=65, kind=CellsBasis.MEM, 
              defaultValues=[], zeroReg=NONE, toString=showMEM, toStringWithSize=showMEMWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_CTRL = CellsBasis.DESC {low=66, high=65, kind=CellsBasis.CTRL, 
              defaultValues=[], zeroReg=NONE, toString=showCTRL, toStringWithSize=showCTRLWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       and desc_CELLSET = CellsBasis.DESC {low=66, high=65, kind=CELLSET, defaultValues=[], 
              zeroReg=NONE, toString=showCELLSET, toStringWithSize=showCELLSETWithSize, 
              counter=ref 0, dedicated=ref 0, physicalRegs=ref CellsBasis.array0}
       val cellKindDescs = [(CellsBasis.GP, desc_GP), (CellsBasis.FP, desc_FP), 
              (CellsBasis.CC, desc_GP), (EFLAGS, desc_EFLAGS), (FFLAGS, desc_FFLAGS), 
              (CellsBasis.MEM, desc_MEM), (CellsBasis.CTRL, desc_CTRL), (CELLSET, 
              desc_CELLSET)]
       val cellSize = 4
      )

   open MyCells
   val addGP = CellSet.add
   and addFP = CellSet.add
   and addCC = CellSet.add
   and addEFLAGS = CellSet.add
   and addFFLAGS = CellSet.add
   and addMEM = CellSet.add
   and addCTRL = CellSet.add
   and addCELLSET = CellSet.add
   val RegGP = Reg GP
   and RegFP = Reg FP
   and RegCC = Reg CC
   and RegEFLAGS = Reg EFLAGS
   and RegFFLAGS = Reg FFLAGS
   and RegMEM = Reg MEM
   and RegCTRL = Reg CTRL
   and RegCELLSET = Reg CELLSET
   val eax = RegGP 0
   val ecx = RegGP 1
   val edx = RegGP 2
   val ebx = RegGP 3
   val esp = RegGP 4
   val ebp = RegGP 5
   val esi = RegGP 6
   val edi = RegGP 7
   val stackptrR = RegGP 4
   val ST = (fn x => RegFP x
            )
   val ST0 = RegFP 0
   val asmTmpR = RegGP 0
   val fasmTmp = RegFP 0
   val eflags = RegEFLAGS 0
end

