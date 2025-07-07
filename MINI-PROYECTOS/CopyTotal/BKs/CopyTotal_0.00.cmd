@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM =================== LOG ========================
set "LOGFILE=C:\SHR8\copy2log.log"
echo ------------------------- >> "%LOGFILE%"
echo %DATE%  -  %TIME%         >> "%LOGFILE%"

REM ============ OBTENER NOMBRE DEL EQUIPO =========
for /f %%N in ('hostname') do set "HOSTNAME=%%N"

REM ============ DETECTAR TIPO DE MAQUINA ==========
set "TipoPC=Comanda"

echo !HOSTNAME! | findstr /i "envios" >nul && set "TipoPC=Envios"
echo !HOSTNAME! | findstr /i "btv buena" >nul && set "TipoPC=BTV"
echo !HOSTNAME! | findstr /i "medico doctor" >nul && set "TipoPC=Medico"

echo Tipo de PC detectado: !TipoPC! >> "%LOGFILE%"

REM ============ OBTENER IP LOCAL Y CALCULAR RANGO ==========
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    for /f "tokens=1-4 delims=." %%i in ("%%a") do (
        set "IP1=%%i"
        set "IP2=%%j"
        set "IP3=%%k"
        set "IP4=%%l"
    )
)

set "Subnet=!IP1!.!IP2!.!IP3!"
set "Server61=!Subnet!.61"
set "Server31=!Subnet!.31"

REM ============ PROBAR CONEXIÓN Y SELECCIONAR SERVER ==========
set "ServerIP="

echo Probandocon !Server61!... >> "%LOGFILE%"
dir "\\!Server61!\SVI$" >nul 2>&1 && set "ServerIP=!Server61!"

if not defined ServerIP (
    echo !Server61! no disponible. Probando !Server31!... >> "%LOGFILE%"
    dir "\\!Server31!\SVI$" >nul 2>&1 && set "ServerIP=!Server31!"
)

if not defined ServerIP (
    echo Ningún servidor accesible. Abortando... >> "%LOGFILE%"
    exit /b 1
)

echo Usando servidor: !ServerIP! >> "%LOGFILE%"

REM ============ COPIAR SVI$\SHR8 A C:\SHR8 ==========
xcopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8\" /E /C /Y >> "%LOGFILE%"

REM ============ COPIAR ESCRITORIOS ==========
xcopy "\\!ServerIP!\SVI$\Desktop" "%UserProfile%\Desktop\" /E /C /Y >> "%LOGFILE%"

if /i "!TipoPC!"=="Envios" (
    xcopy "\\!ServerIP!\SVI$\Desktop_Envios" "%UserProfile%\Desktop\" /E /C /Y >> "%LOGFILE%"
)
if /i "!TipoPC!"=="Medico" (
    xcopy "\\!ServerIP!\SVI$\Desktop_Medico" "%UserProfile%\Desktop\" /E /C /Y >> "%LOGFILE%"
)
if /i "!TipoPC!"=="Comanda" (
    xcopy "\\!ServerIP!\SVI$\Desktop_Comanda" "%UserProfile%\Desktop\" /E /C /Y >> "%LOGFILE%"
)

REM ============ EJECUTAR CMD.CMD SI EXISTE ==========
if exist "C:\SHR8\Copy2\cmd.cmd" (
    echo Ejecutando cmd.cmd >> "%LOGFILE%"
    call "C:\SHR8\Copy2\cmd.cmd"
) else (
    echo cmd.cmd no encontrado. >> "%LOGFILE%"
)

REM ============ DETECTAR USUARIO ESTÁNDAR ==========
for /f "tokens=1,*" %%a in ('"wmic computersystem get username /value"') do (
    for /f "delims=" %%c in ("%%a") do set USERSTD=%%c
)
set "USERSTD=%USERSTD:Username=%"
set "USERSTD=%USERSTD:~1%"
for /f "tokens=2 delims=\" %%u in ("%USERSTD%") do set "USERSTD=%%u"

echo Usuario estándar detectado: %USERSTD% >> "%LOGFILE%"

REM ============ LIMPIAR TEMP CADA 5 DÍAS ==========
for /f %%d in ('powershell -command "(Get-Date).Day"') do set "DAY=%%d"
set /a MODULO=DAY %% 5

if "%MODULO%"=="0" (
    echo Limpiando %TEMP% >> "%LOGFILE%"
    del /f /s /q "%TEMP%\*.*" >nul 2>&1
    for /d %%x in ("%TEMP%\*") do rd /s /q "%%x" >nul 2>&1
)

endlocal
exit /b 0
