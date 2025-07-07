@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ==================== CONFIG ====================
set "SCRIPT_ROOT=C:\SHR8\CopyTotal"
set "LOGFILE=%SCRIPT_ROOT%\copy2log.log"
set "USERS_ROOT=C:\Users\"
set "FALLBACK_SUBNET=10.10.2"
set "TipoPC=Comanda"

REM Crear directorio de logs si no existe
if not exist "%SCRIPT_ROOT%" mkdir "%SCRIPT_ROOT%" >nul 2>&1

echo ========================= >> "%LOGFILE%"
echo INICIO: %DATE% - %TIME% >> "%LOGFILE%"

REM ============ OBTENER NOMBRE DEL EQUIPO =========
for /f %%N in ('hostname') do set "HOSTNAME=%%N"
echo Hostname: !HOSTNAME! >> "%LOGFILE%"

REM ============ DETECTAR TIPO DE MAQUINA ==========
REM set "TipoPC=Comanda"

echo !HOSTNAME! | findstr /i "envios" >nul 2>&1 && set "TipoPC=Envios"
echo !HOSTNAME! | findstr /i "btv buena" >nul 2>&1 && set "TipoPC=BTV"
echo !HOSTNAME! | findstr /i "medico doctor" >nul 2>&1 && set "TipoPC=Medico"

echo Tipo de PC detectado: !TipoPC! >> "%LOGFILE%"

REM Método 1: ipconfig sin archivo temporal
for /f "tokens=*" %%a in ('ipconfig ^| findstr /i "IPv4" 2^>nul') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do (
        set "TEMP_IP=%%b"
        set "TEMP_IP=!TEMP_IP: =!"
        set "TEMP_IP=!TEMP_IP:(Preferred)=!"

        echo !TEMP_IP! | findstr /r "^10\." >nul 2>&1
        if not errorlevel 1 (
            if not defined Subnet (
                for /f "tokens=1,2,3 delims=." %%x in ("!TEMP_IP!") do (
                    set "Subnet=%%x.%%y.%%z"
                    echo IP detectada: !TEMP_IP! ^(Subred: !Subnet!^) >> "%LOGFILE%"
                )
            )
        )
    )
)

REM Si no se detectó IP, usar fallback
if not defined Subnet (
    echo ADVERTENCIA: No se pudo detectar IP local con prefijo 10. Usando fallback: %FALLBACK_SUBNET% >> "%LOGFILE%"
    set "Subnet=%FALLBACK_SUBNET%"
) else (
    echo Subred final: !Subnet! >> "%LOGFILE%"
)

set "IPServer1=%Subnet%.61"
set "IPServer2=%Subnet%.31"

REM ============ DETECTAR USUARIO ESTÁNDAR MEJORADO ==========
set "USERSTD="

REM Método 1: Usuario actualmente logueado
for /f "tokens=2 delims==" %%a in ('wmic computersystem get username /value 2^>nul ^| findstr "="') do (
    set "TEMP_USER=%%a"
    for /f "tokens=2 delims=\" %%b in ("!TEMP_USER!") do set "USERSTD=%%b"
)

REM Método 2: Si no hay usuario logueado, buscar en query session
if not defined USERSTD (
    for /f "tokens=2" %%a in ('query session ^| findstr "Active"') do (
        set "USERSTD=%%a"
    )
)

REM Método 3: Buscar usuario más reciente en Users
if not defined USERSTD (
    for /f "tokens=1" %%a in ('dir "C:\Users" /b /ad /o-d 2^>nul ^| findstr /v /i "public default administrator"') do (
        if not defined USERSTD set "USERSTD=%%a"
    )
)

if defined USERSTD (
    echo Usuario estándar detectado: !USERSTD! >> "%LOGFILE%"
) else (
    echo ADVERTENCIA: No se pudo detectar usuario estándar. >> "%LOGFILE%"
    REM Método 4: Si todo lo anterior falla, usar el usuario actual guardado en la variable de entorno
    echo Se sacara el usuario de la variable de entorno: %USERNAME% >> "%LOGFILE%"
    set "USERSTD=%USERNAME%"
)

set "USERSTD_DIR=%USERS_ROOT%!USERSTD!"
echo Carpeta de Usuario Seleccionada: %USERSTD_DIR% >> "%LOGFILE%"
if not exist "!USERSTD_DIR!" (
    echo ADVERTENCIA: Directorio de usuario no existe: !USERSTD_DIR! >> "%LOGFILE%"
    REM set "USERSTD="
)

REM ============ COPIAR SHR8 COMPLETO ==========
echo Iniciando copia de SHR8... >> "%LOGFILE%"
if exist \\!IPServer1!\SVI$\ (
    set "ServerIP=%IPServer1%"
    echo Fuente: \\!ServerIP!\SVI$\ >> "%LOGFILE%"
) else if exist \\!IPServer2!\SVI$\ (
    set "ServerIP=%IPServer2%"
    echo Fuente: \\!ServerIP!\SVI$\ >> "%LOGFILE%"
) else (
    echo ERROR: No se pudo encontrar SHR8 en ninguno de los servidores. >> "%LOGFILE%"
    echo Verifique las conexiones de red y la disponibilidad de los servidores. >> "%LOGFILE%"
    exit /b 1
)

echo Destino: C:\SHR8 >> "%LOGFILE%"

REM Robocopy maneja mejor los permisos y errores de acceso
robocopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8" /E /Z /MT:4 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" /TEE
set "RC_SHR8=%ERRORLEVEL%"


if !RC_SHR8! gtr 7 (
    echo ERROR1: Fallo crítico en copia de SHR8 (código: !RC_SHR8!) >> "%LOGFILE%"
) else (
    echo Copia de SHR8 completada exitosamente (código: !RC_SHR8!) >> "%LOGFILE%"
    if !RC_SHR8! gtr 0 (
        echo NOTA: Código !RC_SHR8! indica que algunos archivos fueron copiados con advertencias >> "%LOGFILE%"
    )
)

REM ============ COPIAR ESCRITORIOS ==========
REM Copiar escritorio base
if exist "\\!ServerIP!\SVI$\Desktop" (
    echo Copiando escritorio base... >> "%LOGFILE%"
    robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%"
    set "RC_BASE=%ERRORLEVEL%"
    if !RC_BASE! gtr 7 (
        echo ERROR en copia escritorio base (código: !RC_BASE!) >> "%LOGFILE%"
    ) else if !RC_BASE! gtr 16 (
        echo SERIOUS ERROR: Didn't copy any files. Either a usage error or an error due to insufficient access privileges occurred. (código: !RC_BASE!) >> "%LOGFILE%"
    ) else (
        echo Copia escritorio base completada (código: !RC_BASE!) >> "%LOGFILE%"
        if !RC_SHR8! gtr 0 (
            echo NOTA: Código !RC_SHR8! indica que algunos archivos fueron copiados con advertencias >> "%LOGFILE%"
        )
    )
) else (
    echo ADVERTENCIA: No se puede verificar Desktop base >> "%LOGFILE%"
    echo Intentando copia de todas formas... >> "%LOGFILE%"
    robocopy "\\!ServerIP!\SVI$\Desktop" "%userprofile%\Desktop" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" 2>nul
    set "RC_BASE=%ERRORLEVEL%"
    echo Intento de copia escritorio base completado (código: !RC_BASE!) >> "%LOGFILE%"
)

if defined USERSTD (
    echo Iniciando copia de escritorio especifico para usuario: !USERSTD! >> "%LOGFILE%"
    REM Copiar escritorio específico según tipo
    set "DESKTOP_SOURCE="
    if /i "!TipoPC!"=="BTV" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_BTV"
    if /i "!TipoPC!"=="Envios" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Envios"
    if /i "!TipoPC!"=="Medico" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Medico"
    if /i "!TipoPC!"=="Comanda" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Comanda"

    if defined DESKTOP_SOURCE (
        echo Copiando escritorio específico para tipo: !TipoPC! >> "%LOGFILE%"
        echo Fuente: !DESKTOP_SOURCE! >> "%LOGFILE%"
        robocopy "!DESKTOP_SOURCE!" "%userprofile%\Desktop" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" 2>nul
        set "RC_SPECIFIC=%ERRORLEVEL%"
        if !RC_SPECIFIC! gtr 7 (
            echo ERROR en copia escritorio específico (código: !RC_SPECIFIC!) >> "%LOGFILE%"
        ) else (
            echo Copia escritorio específico completada (código: !RC_SPECIFIC!) >> "%LOGFILE%"
            if !RC_SPECIFIC! gtr 0 (
                echo NOTA: Código !RC_SPECIFIC! indica que algunos archivos fueron copiados con advertencias >> "%LOGFILE%"
            )
        )
    )
) else (
    echo SALTANDO: Copia de escritorio especifico (no hay usuario válido) >> "%LOGFILE%"
)

REM ============ EJECUTAR comandos.cmd SI EXISTE ==========
if exist "%SCRIPT_ROOT%\comandos.cmd" (
    echo Ejecutando comandos.cmd... >> "%LOGFILE%"
    call "%SCRIPT_ROOT%\comandos.cmd" >> "%LOGFILE%" 2>&1
    echo comandos.cmd terminado (código: !ERRORLEVEL!) >> "%LOGFILE%"
) else (
    echo comandos.cmd no encontrado >> "%LOGFILE%"
)

REM ============ LIMPIEZA TEMPORAL CADA 5 DÍAS ==========
for /f %%d in ('powershell -command "(Get-Date).Day"') do set "DAY=%%d"
set /a DIVMOD=DAY %% 5

if "%DIVMOD%"=="0" (
    echo Ejecutando limpieza temporal programada... >> "%LOGFILE%"
    del /f /s /q "%TEMP%\*.*" >nul 2>&1
    for /d %%x in ("%TEMP%\*") do rd /s /q "%%x" >nul 2>&1
    echo Limpieza temporal completada >> "%LOGFILE%"
)

REM ============ FINALIZACION DE SCRIPT ==========
echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
echo Proceso completado exitosamente.
endlocal
exit /b 0