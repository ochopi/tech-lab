@echo off
for /f "tokens=1,*" %%a in ('"wmic computersystem get username /value"') do (
    for /f "delims=" %%c in ("%%a") do set USERSTD=%%c
)
set USERSTD=%USERSTD:Username=%
set "USERSTD=%USERSTD:~1%"  & REM elimina el '=' inicial si lo hubiera
set "USERSTD=%USERSTD:~1%"  & REM elimina el '=' inicial si lo hubiera

echo %USERSTD%
pause
