@echo off
setlocal EnableDelayedExpansion

set "ORIGEN=%~dp0"
set "SVILOCAL=%ORIGEN%SVI"
set "CONFIGS=%ORIGEN%SVI-config\"
set "LOGFOLDER=%CONFIGS%logs\"
set "IPFILE=%CONFIGS%ipservers.txt"

for /f "tokens=*" %%I in (%IPFILE%) do (
    start /MIN "RC %%I" robocopy "%SVILOCAL%" "\\%%I\svi$" /E /COPY:DAT /IS /IT /Z /MT:8 /R:2 /W:5 /NP /LOG:"%LOGFOLDER%log_%%I.txt"
)

echo Realizando Copia de SVI hacia todos los servidores. 
echo Para mas detalles revisa los Logs en 
echo %LOGFOLDER%log_[ip].txt
timeout /t 5
exit
