@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ==================== CONFIG ====================
set "SCRIPT_ROOT=C:\SHR8\CopyTotal"
set "LOGFILE=%SCRIPT_ROOT%\copy2log.log"
set "FALLBACK_SUBNET=10.10.2"
set "DEFAULT_SERVER1=%FALLBACK_SUBNET%.61"
set "DEFAULT_SERVER2=%FALLBACK_SUBNET%.31"

REM Crear directorio de logs si no existe
if not exist "%SCRIPT_ROOT%" mkdir "%SCRIPT_ROOT%" >nul 2>&1

echo ========================= >> "%LOGFILE%"
echo INICIO: %DATE% - %TIME% >> "%LOGFILE%"

REM ============ OBTENER NOMBRE DEL EQUIPO =========
for /f %%N in ('hostname') do set "HOSTNAME=%%N"
echo Hostname: !HOSTNAME! >> "%LOGFILE%"

REM ============ DETECTAR TIPO DE MAQUINA ==========
set "TipoPC=Comanda"

echo !HOSTNAME! | findstr /i "envios" >nul 2>&1 && set "TipoPC=Envios"
echo !HOSTNAME! | findstr /i "btv buena" >nul 2>&1 && set "TipoPC=BTV"
echo !HOSTNAME! | findstr /i "medico doctor" >nul 2>&1 && set "TipoPC=Medico"

echo Tipo de PC detectado: !TipoPC! >> "%LOGFILE%"

REM ============ OBTENER IP LOCAL DE ADAPTADOR ACTIVO ==========
set "Subnet="

REM Usar wmic para obtener solo adaptadores conectados con IP válida
for /f "tokens=2 delims=," %%a in ('wmic path win32_networkadapterconfiguration where "IPEnabled=TRUE and DHCPEnabled=TRUE" get IPAddress /format:csv ^| findstr /v "IPAddress" ^| findstr /v "^$"') do (
    if not defined Subnet (
        REM Extraer primera IP si hay múltiples
        set "FULL_IP=%%a"
        set "FULL_IP=!FULL_IP:{=!"
        set "FULL_IP=!FULL_IP:}=!"
        set "FULL_IP=!FULL_IP:"=!"
        
        REM Obtener primer IP de la lista
        for /f "tokens=1 delims=;" %%b in ("!FULL_IP!") do (
            set "FIRST_IP=%%b"
            REM Validar que sea una IP privada válida (192.168, 10.x, 172.16-31)
            echo !FIRST_IP! | findstr /r "^192\.168\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
            if not defined Subnet (
                echo !FIRST_IP! | findstr /r "^10\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
            )
            if not defined Subnet (
                echo !FIRST_IP! | findstr /r "^172\.[123][0-9]\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
            )
        )
    )
)

REM Si no se encontró con DHCP, intentar con adaptadores estáticos
if not defined Subnet (
    for /f "tokens=2 delims=," %%a in ('wmic path win32_networkadapterconfiguration where "IPEnabled=TRUE" get IPAddress /format:csv ^| findstr /v "IPAddress" ^| findstr /v "^$"') do (
        if not defined Subnet (
            set "FULL_IP=%%a"
            set "FULL_IP=!FULL_IP:{=!"
            set "FULL_IP=!FULL_IP:}=!"
            set "FULL_IP=!FULL_IP:"=!"
            
            for /f "tokens=1 delims=;" %%b in ("!FULL_IP!") do (
                set "FIRST_IP=%%b"
                echo !FIRST_IP! | findstr /r "^192\.168\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
                if not defined Subnet (
                    echo !FIRST_IP! | findstr /r "^10\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
                )
                if not defined Subnet (
                    echo !FIRST_IP! | findstr /r "^172\.[123][0-9]\." >nul 2>&1 && call :ExtractSubnet "!FIRST_IP!"
                )
            )
        )
    )
)

if not defined Subnet (
    echo No se pudo obtener IP local de adaptador activo. Usando fallback: %FALLBACK_SUBNET% >> "%LOGFILE%"
    set "Subnet=%FALLBACK_SUBNET%"
) else (
    echo Subred detectada: !Subnet! >> "%LOGFILE%"
)

set "Server61=%Subnet%.61"
set "Server31=%Subnet%.31"

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
    set "USERSTD_DIR=C:\Users\!USERSTD!"
    if not exist "!USERSTD_DIR!" (
        echo ADVERTENCIA: Directorio de usuario no existe: !USERSTD_DIR! >> "%LOGFILE%"
        set "USERSTD="
    )
) else (
    echo ADVERTENCIA: No se pudo detectar usuario estándar. >> "%LOGFILE%"
)

REM ============ PROBAR CONEXIÓN EN PARALELO ==========
set "ServerIP="
set "TEMP_RESULT=%TEMP%\server_test.tmp"

echo Probando conectividad con servidores... >> "%LOGFILE%"

REM Probar ambos servidores en paralelo
start /b cmd /c "call :TestServerAsync "!Server61!" "!TEMP_RESULT!.61""
start /b cmd /c "call :TestServerAsync "!Server31!" "!TEMP_RESULT!.31""

REM Esperar hasta 10 segundos por una respuesta
set /a WAIT_COUNT=0
:WaitLoop
timeout /t 1 /nobreak >nul 2>&1
set /a WAIT_COUNT+=1

if exist "!TEMP_RESULT!.61" (
    set "ServerIP=!Server61!"
    del "!TEMP_RESULT!.31" >nul 2>&1
    goto :ServerFound
)
if exist "!TEMP_RESULT!.31" (
    set "ServerIP=!Server31!"
    del "!TEMP_RESULT!.61" >nul 2>&1
    goto :ServerFound
)

if !WAIT_COUNT! lss 10 goto :WaitLoop

REM Limpiar archivos temporales
del "!TEMP_RESULT!.*" >nul 2>&1

REM Si no funcionó, intentar con servidores default
if not defined ServerIP (
    echo Probando con servidores default... >> "%LOGFILE%"
    call :TryConnect "%DEFAULT_SERVER1%" && set "ServerIP=%DEFAULT_SERVER1%"
    if not defined ServerIP (
        call :TryConnect "%DEFAULT_SERVER2%" && set "ServerIP=%DEFAULT_SERVER2%"
    )
)

:ServerFound
if not defined ServerIP (
    echo ERROR: Ningún servidor disponible. Abortando. >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    exit /b 1
)

echo Servidor seleccionado: !ServerIP! >> "%LOGFILE%"

REM ============ VERIFICAR ACCESO AL SERVIDOR ==========
if not exist "\\!ServerIP!\SVI$\SHR8" (
    echo ERROR: No se puede acceder a \\!ServerIP!\SVI$\SHR8 >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    exit /b 2
)

REM ============ COPIAR SHR8 COMPLETO ==========
echo Iniciando copia de SHR8... >> "%LOGFILE%"
robocopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8\" /E /Z /MT:4 /R:2 /W:2 /XO /NFL /NDL /NP /LOG+:"%LOGFILE%"
set "RC_SHR8=%ERRORLEVEL%"

if !RC_SHR8! gtr 7 (
    echo ERROR: Fallo crítico en copia de SHR8 (código: !RC_SHR8!) >> "%LOGFILE%"
) else (
    echo Copia de SHR8 completada (código: !RC_SHR8!) >> "%LOGFILE%"
)

REM ============ COPIAR ESCRITORIO SI HAY USUARIO ==========
if defined USERSTD (
    echo Iniciando copia de escritorio para usuario: !USERSTD! >> "%LOGFILE%"
    
    REM Copiar escritorio base
    if exist "\\!ServerIP!\SVI$\Desktop" (
        robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:2 /W:2 /XO /NFL /NDL /NP /LOG+:"%LOGFILE%"
        set "RC_BASE=%ERRORLEVEL%"
        echo Copia escritorio base completada (código: !RC_BASE!) >> "%LOGFILE%"
    ) else (
        echo ADVERTENCIA: No existe Desktop base en servidor >> "%LOGFILE%"
    )

    REM Copiar escritorio específico según tipo
    set "DESKTOP_SOURCE="
    if /i "!TipoPC!"=="BTV" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_BTV"
    if /i "!TipoPC!"=="Envios" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Envios"
    if /i "!TipoPC!"=="Medico" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Medico"
    if /i "!TipoPC!"=="Comanda" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Comanda"

    if defined DESKTOP_SOURCE (
        if exist "!DESKTOP_SOURCE!" (
            echo Copiando escritorio específico: !DESKTOP_SOURCE! >> "%LOGFILE%"
            robocopy "!DESKTOP_SOURCE!" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:2 /W:2 /XO /NFL /NDL /NP /LOG+:"%LOGFILE%"
            set "RC_SPECIFIC=%ERRORLEVEL%"
            echo Copia escritorio específico completada (código: !RC_SPECIFIC!) >> "%LOGFILE%"
        ) else (
            echo ADVERTENCIA: No existe !DESKTOP_SOURCE! en servidor >> "%LOGFILE%"
        )
    )
) else (
    echo SALTANDO: Copia de escritorio (no hay usuario válido) >> "%LOGFILE%"
)

REM ============ EJECUTAR cmd.cmd SI EXISTE ==========
if exist "%SCRIPT_ROOT%\cmd.cmd" (
    echo Ejecutando cmd.cmd... >> "%LOGFILE%"
    call "%SCRIPT_ROOT%\cmd.cmd" >> "%LOGFILE%" 2>&1
    echo cmd.cmd terminado (código: !ERRORLEVEL!) >> "%LOGFILE%"
) else (
    echo cmd.cmd no encontrado >> "%LOGFILE%"
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

echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
endlocal
exit /b 0

REM ========== FUNCIONES ==========

:ExtractSubnet
set "FULL_IP=%~1"
for /f "tokens=1,2,3,4 delims=." %%a in ("%FULL_IP%") do (
    set "Subnet=%%a.%%b.%%c"
)
exit /b 0

:TryConnect
set "IPT=%~1"
ping -n 1 -w 1000 "%IPT%" >nul 2>&1
if %errorlevel% equ 0 (
    dir "\\%IPT%\SVI$" >nul 2>&1
    if %errorlevel% equ 0 (
        exit /b 0
    )
)
exit /b 1

:TestServerAsync
set "SERVER=%~1"
set "RESULT_FILE=%~2"
call :TryConnect "%SERVER%"
if %errorlevel% equ 0 (
    echo OK > "%RESULT_FILE%"
)
exit /b 0