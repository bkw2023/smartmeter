@echo off
rem Daten aus chart*.svg Files in csv File extrahieren

SET dirli=jan feb mar apr mai jun jul aug sep okt nov dez 
SET tmpdir=

goto :main

:performdir
  SET tmpdir=F:\Standartprofile\vorw_tag_1P\%1
  @echo perform dir %tmpdir%
  SUBST U: %tmpdir%
  for %%f in (U:*.svg) do call :performfile %%f  
  SUBST U: /D
goto :eof

:performfile
  @echo perform file %1
  copy %1 tmp.svg
  call DelphiSplitXML.exe tmp.svg -b
  call ExtractStandardData.exe tmp.txt -b
  type tmp.csv >> all.csv
  del tmp.svg tmp.txt tmp.csv 
goto :eof

:main
@echo in main
for %%d in (%dirli%) do call :performdir %%d

@echo.
@echo F E R T I G
pause



