@echo off
setlocal EnableDelayedExpansion

REM Escriba aqui si desea copiar solo una carpeta especifica dentro de SHR8$ por ejemplo
REM set "CPFOLDER=\Config\RCopy"    de lo contrario dejarlo en blanco     set "CPFOLDER="

set "CPFOLDER=\Config\RCopy"

set "ORIGEN=%~dp0"
set "SHR8LOCAL=%ORIGEN%SVI\SHR8"
set "CONFIGS=%ORIGEN%SVI-config\"
set "LOGFOLDER=%CONFIGS%logs\comandas\"
set "IPFILE=%CONFIGS%ipcomandas.txt"

for /f "tokens=*" %%I in (%IPFILE%) do (
    start /MIN "RC %%I" robocopy "%SHR8LOCAL%%CPFOLDER%" "\\%%I\shr8$%CPFOLDER%" /E /COPY:DAT /IS /IT /Z /MT:8 /R:2 /W:5 /NP /LOG:"%LOGFOLDER%log_%%I.txt"
)

echo Realizando Copia de SVI hacia todos los servidores. 
echo Para mas detalles revisa los Logs en 
echo %LOGFOLDER%log_[ip].txt
timeout /t 5
exit
