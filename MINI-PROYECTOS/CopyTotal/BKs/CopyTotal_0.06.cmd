@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ==================== CONFIG ====================
set "SCRIPT_ROOT=C:\SHR8\CopyTotal"
set "LOGFILE=%SCRIPT_ROOT%\copy2log.log"
set "USERS_ROOT=C:\Users\"
set "FALLBACK_SUBNET=10.10.2"
REM set "DEFAULT_SERVER1=%FALLBACK_SUBNET%.61"
set "DEFAULT_SERVER1=61"
set "DEFAULT_SERVER2=31"
set "TipoPC=Comanda"

REM Credenciales de dominio de último recurso
REM set "USERDEF=usuario_generico"
REM set "PASSDEF=password_generico"

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

REM ============ OBTENER IP LOCAL SIMPLE ==========
set "Subnet="

echo Detectando IP local... >> "%LOGFILE%"

REM Método 1: ipconfig simple con timeout
set "TMPFILE=%TEMP%\_ipconfig_simple.txt"
timeout /t 5 /nobreak >nul 2>&1 & ipconfig > "%TMPFILE%" 2>nul

REM Buscar líneas que contengan IPv4 y que empiecen con 10
for /f "tokens=*" %%a in ('findstr /i "IPv4" "%TMPFILE%" 2^>nul') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do (
        set "TEMP_IP=%%b"
        set "TEMP_IP=!TEMP_IP: =!"
        set "TEMP_IP=!TEMP_IP:(Preferred)=!"
        
        REM Solo procesar si empieza con 10
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

REM Método 2: Si falló, intentar con wmic simple
if not defined Subnet (
    echo Probando método alternativo... >> "%LOGFILE%"
    for /f "skip=1 tokens=*" %%a in ('wmic path win32_networkadapterconfiguration where "IPEnabled=TRUE" get IPAddress /value 2^>nul') do (
        if not defined Subnet (
            set "LINE=%%a"
            if defined LINE (
                echo !LINE! | findstr /i "IPAddress" >nul 2>&1
                if not errorlevel 1 (
                    for /f "tokens=2 delims==" %%b in ("!LINE!") do (
                        set "IP_RAW=%%b"
                        set "IP_RAW=!IP_RAW:{=!"
                        set "IP_RAW=!IP_RAW:}=!"
                        set "IP_RAW=!IP_RAW:"=!"
                        
                        REM Obtener primera IP de la lista
                        for /f "tokens=1 delims=," %%c in ("!IP_RAW!") do (
                            set "CLEAN_IP=%%c"
                            echo !CLEAN_IP! | findstr /r "^10\." >nul 2>&1
                            if not errorlevel 1 (
                                for /f "tokens=1,2,3 delims=." %%x in ("!CLEAN_IP!") do (
                                    set "Subnet=%%x.%%y.%%z"
                                    echo IP detectada: !CLEAN_IP! ^(Subred: !Subnet!^) >> "%LOGFILE%"
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

REM Limpiar archivos temporales
del "%TMPFILE%" >nul 2>&1

REM Si no se detectó IP, usar fallback
if not defined Subnet (
    echo ADVERTENCIA: No se pudo detectar IP local con prefijo 10. Usando fallback: %FALLBACK_SUBNET% >> "%LOGFILE%"
    set "Subnet=%FALLBACK_SUBNET%"
) else (
    echo Subred final: !Subnet! >> "%LOGFILE%"
)

set "IPServer1=%Subnet%.%DEFAULT_SERVER1%"
set "IPServer2=%Subnet%.%DEFAULT_SERVER2%"

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
    set "USERSTD="
)

REM ============ PROBAR CONEXIÓN CON PING MÚLTIPLE ==========
set "ServerIP="

echo Probando conectividad con servidores... >> "%LOGFILE%"

REM Función para ping múltiple
:ping_multiple
set "TARGET_IP=%~1"
set "PING_SUCCESS=false"
echo Probando servidor: !TARGET_IP! >> "%LOGFILE%"

REM Intentar ping 3 veces
for /l %%i in (1,1,3) do (
    ping -n 1 -w 3000 "!TARGET_IP!" >nul 2>&1
    if not errorlevel 1 (
        echo Ping exitoso a !TARGET_IP! (intento %%i/3) >> "%LOGFILE%"
        set "PING_SUCCESS=true"
        goto :ping_done
    ) else (
        echo Ping falló a !TARGET_IP! (intento %%i/3) >> "%LOGFILE%"
        if %%i lss 3 timeout /t 2 /nobreak >nul 2>&1
    )
)
:ping_done
exit /b

REM Probar IPServer1 primero
call :ping_multiple "!IPServer1!"
if "!PING_SUCCESS!"=="true" (
    set "ServerIP=!IPServer1!"
    echo Servidor !IPServer1! seleccionado >> "%LOGFILE%"
)

REM Si no funcionó, probar IPServer2
if not defined ServerIP (
    call :ping_multiple "!IPServer2!"
    if "!PING_SUCCESS!"=="true" (
        set "ServerIP=!IPServer2!"
        echo Servidor !IPServer2! seleccionado >> "%LOGFILE%"
    )
)

REM Si no funcionó con la subred detectada, intentar con servidores default
REM if not defined ServerIP (
REM    echo Probando con servidores default... >> "%LOGFILE%"
REM    call :ping_multiple "%DEFAULT_SERVER1%"
REM    if "!PING_SUCCESS!"=="true" (
REM        set "ServerIP=%DEFAULT_SERVER1%"
REM        echo Servidor default %DEFAULT_SERVER1% seleccionado >> "%LOGFILE%"
REM    )
REM )
REM 
REM if not defined ServerIP (
REM     call :ping_multiple "%DEFAULT_SERVER2%"
REM     if "!PING_SUCCESS!"=="true" (
REM         set "ServerIP=%DEFAULT_SERVER2%"
REM         echo Servidor default %DEFAULT_SERVER2% seleccionado >> "%LOGFILE%"
REM     )
REM )

if not defined ServerIP (
    echo ERROR: Ningún servidor disponible via ping. Abortando. >> "%LOGFILE%"
    echo Detalles de diagnóstico: >> "%LOGFILE%"
    echo - Subred detectada: !Subnet! >> "%LOGFILE%"
    echo - Servidores probados: !IPServer1!, !IPServer2!, %DEFAULT_SERVER1%, %DEFAULT_SERVER2% >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    exit /b 1
)

echo Servidor seleccionado: !ServerIP! >> "%LOGFILE%"


REM ============ COPIAR SHR8 COMPLETO ==========
echo Iniciando copia de SHR8... >> "%LOGFILE%"
echo Fuente: \\!ServerIP!\SVI$\SHR8 >> "%LOGFILE%"
echo Destino: C:\SHR8\ >> "%LOGFILE%"

REM Robocopy maneja mejor los permisos y errores de acceso
robocopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8\" /E /Z /MT:4 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" /TEE
set "RC_SHR8=%ERRORLEVEL%"

if !RC_SHR8! gtr 7 (
    echo ERROR: Fallo crítico en copia de SHR8 (código: !RC_SHR8!) >> "%LOGFILE%"
) else (
    echo Copia de SHR8 completada exitosamente (código: !RC_SHR8!) >> "%LOGFILE%"
    if !RC_SHR8! gtr 0 (
        echo NOTA: Código !RC_SHR8! indica que algunos archivos fueron copiados con advertencias >> "%LOGFILE%"
    )
)

REM ============ COPIAR ESCRITORIO SI HAY USUARIO ==========
REM Copiar escritorio base
if exist "\\!ServerIP!\SVI$\Desktop" (
    echo Copiando escritorio base... >> "%LOGFILE%"
    robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%"
    set "RC_BASE=%ERRORLEVEL%"
    if !RC_BASE! gtr 7 (
        echo ERROR en copia escritorio base (código: !RC_BASE!) >> "%LOGFILE%"
    ) else (
        echo Copia escritorio base completada (código: !RC_BASE!) >> "%LOGFILE%"
    )
) else (
    echo ADVERTENCIA: No se puede verificar Desktop base >> "%LOGFILE%"
    echo Intentando copia de todas formas... >> "%LOGFILE%"
    robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" 2>nul
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
        robocopy "!DESKTOP_SOURCE!" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" 2>nul
        set "RC_SPECIFIC=%ERRORLEVEL%"
        if !RC_SPECIFIC! gtr 7 (
            echo ERROR en copia escritorio específico (código: !RC_SPECIFIC!) >> "%LOGFILE%"
        ) else (
            echo Copia escritorio específico completada (código: !RC_SPECIFIC!) >> "%LOGFILE%"
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