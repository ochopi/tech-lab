@echo off
REM Comando que solicita elevacion a Administrador
net session >nul 2>&1 || (powershell -c "Start-Process '%~f0' -Verb RunAs" & exit /b)

REM   ESCRIBE TU AQUÍ TU CÓDIGO A CONTINUACION
echo Forma basica y sencilla de hacer que un CMD solicite elevacion como administrador
pause
EXIT




