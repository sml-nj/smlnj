structure NoWhere =
struct

local

   val i2s = Int.toString

   val basis =
       "datatype 'a list = nil | :: of 'a * 'a list "^
       "datatype 'a option = NONE | SOME of 'a "^
       "datatype order = LESS | EQUAL | GREATER "

   val version = "1.2.2"

   fun WARNING file =
        "(* WARNING: this is generated by running 'nowhere "^file^"'.\n"^
        " * Do not edit this file directly.\n"^
        " * Version "^version^"\n"^
        " *)\n"

   structure Ast     = MDLAst
   structure AstUtil = MDLAstUtil(MDLAst)
   structure AstPP   = MDLAstPrettyPrinter(AstUtil) 
   structure AstRewriter = MDLAstRewriter(MDLAst)
   structure MG = MatchGen(structure AstPP   = AstPP
                           structure AstUtil = AstUtil
                           structure AstRewriter = AstRewriter)
   structure LitMap = MG.LitMap
   structure Parser = MDLParserDriver
      (structure AstPP = AstPP val MDLmode = false val extraCells = [])
   structure MC = MG.MC

   open Ast MDLError AstUtil
   val NO = AstRewriter.noRewrite
   val rw = AstRewriter.rewrite
   val ++ = PP.++
   infix ++
in


   fun gen filename =
   let (* parse file *)
       val program = Parser.load filename

       val ()      = MG.init()

       (* By default, we take after ML *)
       fun failure() = RAISEexp(ID "Match")

       val literals = ref MG.LitMap.empty
     
       fun trans[LOCALdecl(defs, body)] =
           let val basis = Parser.parseString basis
               val dts = MG.compileTypes(basis @ defs)

               (* Translate a case statement *)
               fun compileCase(root, clauses) = 
               let val dfa = MG.compile dts clauses
                   val _   = MG.report{warning=warning, error=error,
                                       log=log, dfa=dfa, rules=clauses}
                   (* val _   = print(MG.MC.toString dfa) *)
               in  MG.codeGen{root=root, dfa=dfa, fail=failure, 
                              literals=literals}
               end handle MC.MatchCompiler msg => 
                     (error msg; CASEexp(root,clauses)) (* just continue *)
 
               fun exp _ (e as CASEexp(r,cs)) = (* case expr *)
                   if MG.isComplex cs then compileCase(r, cs) else e
                 | exp _ e = e

               fun fbind (fb as FUNbind(f,cs as c::_)) = 
                   if MG.isComplex cs then (* expand function *)
                   let val CLAUSE(args,_,_) = c
                       val arity = length args
                       val vars  = List.tabulate(arity, fn i => "p_"^i2s i)
                       val root  = TUPLEexp(map ID vars)
                       val cs'   = map (fn CLAUSE(ps, g, e) =>
                                           CLAUSE([TUPLEpat ps], g, e)) cs
                       val body  = compileCase(root, cs')
                   in  FUNbind(f, [CLAUSE(map IDpat vars, NONE, body)])
                   end
                   else fb 
                 | fbind fb = fb

               fun decl _ (FUNdecl(fbs)) = FUNdecl(map fbind fbs) 
                 | decl _ d  = d

               val prog = 
                  #decl(rw{exp=exp,ty=NO,pat=NO,decl=decl,sexp=NO})
                       (SEQdecl body)

               fun lit _ (VALdecl[VALbind(WILDpat,
                                          LITexp(STRINGlit "literals"))]) =
                     VALdecl(LitMap.foldri (fn (l,v,d) =>
                               VALbind(IDpat v,LITexp l)::d) []
                                  (!literals)) before literals := LitMap.empty
                 | lit _ d = d 
        
               val prog = #decl(rw{exp=NO,ty=NO,pat=NO,decl=lit,sexp=NO}) prog
           in  if LitMap.numItems(!literals) > 0 then
                  fail "missing declaration val _ = \"literals\""  
               else ();
               prog
           end
        | trans[SEQdecl d] = trans d
        | trans[MARKdecl(_,d)] = trans [d]
        | trans _ = fail "program must be wrapped with local"

       val program = trans program
       val text    = PP.text(PP.setmode "code" ++ 
                             PP.textWidth 160 ++ 
                             AstPP.decl program)
   in  WARNING filename^text 
   end 

   fun main x = GenFile.gen {program="nowhere",
                             fileSuffix="sml",
                             trans=gen
                            } x

end

end
