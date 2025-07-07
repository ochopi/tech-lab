@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ==================== CONFIG ====================
set "SCRIPT_ROOT=C:\SHR8\CopyTotal"
set "LOGFILE=%SCRIPT_ROOT%\copy2log.log"
set "FALLBACK_SUBNET=10.10.2"
set "DEFAULT_SERVER1=%FALLBACK_SUBNET%.61"
set "DEFAULT_SERVER2=%FALLBACK_SUBNET%.31"

echo ------------------------- >> "%LOGFILE%"
echo %DATE%  -  %TIME%         >> "%LOGFILE%"

REM ============ OBTENER NOMBRE DEL EQUIPO =========
for /f %%N in ('hostname') do set "HOSTNAME=%%N"

REM ============ DETECTAR TIPO DE MAQUINA ==========
set "TipoPC=Comanda"

echo !HOSTNAME! | findstr /i "envios" >nul 2>&1 && set "TipoPC=Envios"
echo !HOSTNAME! | findstr /i "btv buena" >nul 2>&1 && set "TipoPC=BTV"
echo !HOSTNAME! | findstr /i "medico doctor" >nul 2>&1 && set "TipoPC=Medico"

echo Tipo de PC detectado: !TipoPC! >> "%LOGFILE%"

REM ============ OBTENER IP LOCAL DE FORMA SEGURA ==========
set "Subnet="

REM Guardar salida de ipconfig filtrada en un archivo temporal
set "TMPFILE=%TEMP%\_ipconfig.txt"
ipconfig > "%TMPFILE%" 2>nul

findstr /i /c:"IPv4" "%TMPFILE%" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims=:" %%a in ('findstr /i /c:"IPv4" "%TMPFILE%"') do (
        for /f "tokens=1-4 delims=." %%i in ("%%a") do (
            set "IP1=%%i"
            set "IP2=%%j"
            set "IP3=%%k"
            set "Subnet=%%i.%%j.%%k"
        )
    )
) else (
    echo No se encontró línea IPv4 en ipconfig. >> "%LOGFILE%"
)

del "%TMPFILE%" >nul 2>&1

if not defined Subnet (
    echo No se pudo obtener IP local. Usando IP default: %FALLBACK_SUBNET% >> "%LOGFILE%"
    set "Subnet=%FALLBACK_SUBNET%"
)

echo Subred detectada: !Subnet! >> "%LOGFILE%"

set "Server61=%Subnet%.61"
set "Server31=%Subnet%.31"

REM ============ PROBAR CONEXIÓN DOBLE ==========

set "ServerIP="

REM -- INTENTAR .61 DOS VECES
call :TryConnect "!Server61!" && set "ServerIP=!Server61!"
if not defined ServerIP (
    timeout /t 2 >nul
    call :TryConnect "!Server61!" && set "ServerIP=!Server61!"
)

REM -- INTENTAR .31 DOS VECES
if not defined ServerIP (
    call :TryConnect "!Server31!" && set "ServerIP=!Server31!"
)
if not defined ServerIP (
    timeout /t 2 >nul
    call :TryConnect "!Server31!" && set "ServerIP=!Server31!"
)

REM -- FALLBACKS SI NINGUNA FUNCIONA
if not defined ServerIP (
    echo Fallaron ambas IPs calculadas. Intentando con fallback IPs... >> "%LOGFILE%"
    call :TryConnect "%DEFAULT_SERVER1%" && set "ServerIP=%DEFAULT_SERVER1%"
    if not defined ServerIP (
        timeout /t 2 >nul
        call :TryConnect "%DEFAULT_SERVER1%" && set "ServerIP=%DEFAULT_SERVER1%"
    )
    if not defined ServerIP (
        call :TryConnect "%DEFAULT_SERVER2%" && set "ServerIP=%DEFAULT_SERVER2%"
        if not defined ServerIP (
            timeout /t 2 >nul
            call :TryConnect "%DEFAULT_SERVER2%" && set "ServerIP=%DEFAULT_SERVER2%"
        )
    )
)

if not defined ServerIP (
    echo Ningún servidor disponible. Abortando. >> "%LOGFILE%"
    exit /b 1
)

echo Usando servidor: !ServerIP! >> "%LOGFILE%"

REM ============ DETECTAR USUARIO ESTÁNDAR ==========
set "USERSTD="

for /f "tokens=1,*" %%a in ('"wmic computersystem get username /value"') do (
    for /f "delims=" %%c in ("%%a") do set USERSTD=%%c
)
if defined USERSTD (
    set "USERSTD=%USERSTD:Username=%"
    set "USERSTD=%USERSTD:~1%"
    for /f "tokens=2 delims=\" %%u in ("%USERSTD%") do set "USERSTD=%%u"
    echo Usuario estándar detectado: %USERSTD% >> "%LOGFILE%"
) else (
    echo No se pudo detectar usuario estándar. >> "%LOGFILE%"
)


REM ============ COPIAR SVI$\SHR8 A DESTINO ==========
REM ============ COPIAR SHR8 COMPLETO ==========
robocopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8\" /E /Z /R:2 /W:2 /NFL /NDL /NP /LOG+:"%LOGFILE%"

REM ============ COPIAR ESCRITORIO BASE ===============
set "USERSTD_DIR=C:\Users\!USERSTD!"
robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop\" /E /Z /R:2 /W:2 /NFL /NDL /NP /LOG+:"%LOGFILE%"

REM ============ COPIAR ESCRITORIO SEGÚN TIPO =======
if /i "!TipoPC!"=="Envios" (
    robocopy "\\!ServerIP!\SVI$\Desktop_Envios" "!USERSTD_DIR!\Desktop\" /E /Z /R:2 /W:2 /NFL /NDL /NP /LOG+:"%LOGFILE%"
)
if /i "!TipoPC!"=="Medico" (
    robocopy "\\!ServerIP!\SVI$\Desktop_Medico" "!USERSTD_DIR!\Desktop\" /E /Z /R:2 /W:2 /NFL /NDL /NP /LOG+:"%LOGFILE%"
)
if /i "!TipoPC!"=="Comanda" (
    robocopy "\\!ServerIP!\SVI$\Desktop_Comanda" "!USERSTD_DIR!\Desktop\" /E /Z /R:2 /W:2 /NFL /NDL /NP /LOG+:"%LOGFILE%"
)

REM ============ EJECUTAR cmd.cmd SI EXISTE ==========
if exist "%SCRIPT_ROOT%\cmd.cmd" (
    echo Ejecutando cmd.cmd >> "%LOGFILE%"
    call "%SCRIPT_ROOT%\cmd.cmd"
) else (
    echo cmd.cmd no encontrado. >> "%LOGFILE%"
)


REM ============ LIMPIEZA TEMPORAL CADA 5 DÍAS ==========
for /f %%d in ('powershell -command "(Get-Date).Day"') do set "DAY=%%d"
set /a DIVMOD=DAY %% 5

if "%DIVMOD%"=="0" (
    echo Limpiando %TEMP% >> "%LOGFILE%"
    del /f /s /q "%TEMP%\*.*" >nul 2>&1
    for /d %%x in ("%TEMP%\*") do rd /s /q "%%x" >nul 2>&1
)

endlocal
exit /b 0

REM ========== FUNCIONES ==========
:TryConnect
REM Intenta dos veces acceder al recurso compartido
set "IPT=%~1"
dir "\\%IPT%\SVI$" >nul 2>&1 && dir "\\%IPT%\SVI$" >nul 2>&1 && exit /b 0
exit /b 1
