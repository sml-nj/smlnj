@ECHO off
%COMSPEC% /C "..\bin\ml-build -D NO_ML_LEX -D NO_ML_YACC ml-burg.cm Main.main ml-burg"
%COMSPEC% /C "..\bin\sml -m $smlnj/library-install.cm tool/mlburg-tool.cm ..\lib"
%COMSPEC% /C "..\bin\sml -m $smlnj/library-install.cm tool/burg-ext.cm ..\lib"