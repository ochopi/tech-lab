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

REM Si no se detectó IP, usar fallback sin fallar
if not defined Subnet (
    echo ADVERTENCIA: No se pudo detectar IP local con prefijo 10. Usando fallback: %FALLBACK_SUBNET% >> "%LOGFILE%"
    set "Subnet=%FALLBACK_SUBNET%"
) else (
    echo Subred final: !Subnet! >> "%LOGFILE%"
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

REM ============ PROBAR CONEXIÓN BASADA EN PING ==========
set "ServerIP="

echo Probando conectividad con servidores... >> "%LOGFILE%"
echo Probando servidor: !Server61! >> "%LOGFILE%"

REM Probar Server61 primero
ping -n 1 -w 2000 "!Server61!" >nul 2>&1
if not errorlevel 1 (
    echo Ping exitoso a !Server61! - Servidor disponible >> "%LOGFILE%"
    set "ServerIP=!Server61!"
) else (
    echo Ping falló a !Server61! >> "%LOGFILE%"
)

REM Si no funcionó, probar Server31
if not defined ServerIP (
    echo Probando servidor: !Server31! >> "%LOGFILE%"
    ping -n 1 -w 2000 "!Server31!" >nul 2>&1
    if not errorlevel 1 (
        echo Ping exitoso a !Server31! - Servidor disponible >> "%LOGFILE%"
        set "ServerIP=!Server31!"
    ) else (
        echo Ping falló a !Server31! >> "%LOGFILE%"
    )
)

REM Si no funcionó con la subred detectada, intentar con servidores default
if not defined ServerIP (
    echo Probando con servidores default... >> "%LOGFILE%"
    echo Probando servidor default: %DEFAULT_SERVER1% >> "%LOGFILE%"
    
    ping -n 1 -w 2000 "%DEFAULT_SERVER1%" >nul 2>&1
    if not errorlevel 1 (
        echo Ping exitoso a %DEFAULT_SERVER1% - Servidor disponible >> "%LOGFILE%"
        set "ServerIP=%DEFAULT_SERVER1%"
    ) else (
        echo Ping falló a %DEFAULT_SERVER1% >> "%LOGFILE%"
    )
)

if not defined ServerIP (
    echo Probando servidor default: %DEFAULT_SERVER2% >> "%LOGFILE%"
    ping -n 1 -w 2000 "%DEFAULT_SERVER2%" >nul 2>&1
    if not errorlevel 1 (
        echo Ping exitoso a %DEFAULT_SERVER2% - Servidor disponible >> "%LOGFILE%"
        set "ServerIP=%DEFAULT_SERVER2%"
    ) else (
        echo Ping falló a %DEFAULT_SERVER2% >> "%LOGFILE%"
    )
)

if not defined ServerIP (
    echo ERROR: Ningún servidor disponible via ping. Abortando. >> "%LOGFILE%"
    echo Detalles de diagnóstico: >> "%LOGFILE%"
    echo - Subred detectada: !Subnet! >> "%LOGFILE%"
    echo - Servidores probados: !Server61!, !Server31!, %DEFAULT_SERVER1%, %DEFAULT_SERVER2% >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    pause
    exit /b 1
)

echo Servidor seleccionado: !ServerIP! >> "%LOGFILE%"

REM ============ VERIFICAR ACCESO AL SERVIDOR ==========
if not exist "\\!ServerIP!\SVI$\SHR8" (
    echo ERROR: No se puede acceder a \\!ServerIP!\SVI$\SHR8 >> "%LOGFILE%"
    echo Probando crear conexión con credenciales... >> "%LOGFILE%"
    
    REM Intentar mapear temporalmente
    net use \\!ServerIP!\SVI$ /persistent:no >nul 2>&1
    
    if not exist "\\!ServerIP!\SVI$\SHR8" (
        echo ERROR CRÍTICO: Carpeta SHR8 no existe en servidor >> "%LOGFILE%"
        echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
        pause
        exit /b 2
    ) else (
        echo Acceso a SHR8 exitoso después de mapeo >> "%LOGFILE%"
    )
)

REM ============ COPIAR SHR8 COMPLETO ==========
echo Iniciando copia de SHR8... >> "%LOGFILE%"
echo Fuente: \\!ServerIP!\SVI$\SHR8 >> "%LOGFILE%"
echo Destino: C:\SHR8\ >> "%LOGFILE%"

REM Robocopy maneja mejor los permisos y errores de acceso
robocopy "\\!ServerIP!\SVI$\SHR8" "C:\SHR8\" /E /Z /MT:4 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" /TEE
set "RC_SHR8=%ERRORLEVEL%"

if !RC_SHR8! gtr 7 (
    echo ERROR: Fallo crítico en copia de SHR8 (código: !RC_SHR8!) >> "%LOGFILE%"
    echo Posibles causas: >> "%LOGFILE%"
    echo - Problemas de permisos (administrador local vs dominio) >> "%LOGFILE%"
    echo - Servidor no disponible >> "%LOGFILE%"
    echo - Carpeta fuente no existe >> "%LOGFILE%"
) else (
    echo Copia de SHR8 completada exitosamente (código: !RC_SHR8!) >> "%LOGFILE%"
    if !RC_SHR8! gtr 0 (
        echo NOTA: Código !RC_SHR8! indica que algunos archivos fueron copiados con advertencias >> "%LOGFILE%"
    )
)

REM ============ COPIAR ESCRITORIO SI HAY USUARIO ==========
if defined USERSTD (
    echo Iniciando copia de escritorio para usuario: !USERSTD! >> "%LOGFILE%"
    
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
        echo ADVERTENCIA: No se puede verificar Desktop base - puede ser problema de permisos >> "%LOGFILE%"
        echo Intentando copia de todas formas... >> "%LOGFILE%"
        robocopy "\\!ServerIP!\SVI$\Desktop" "!USERSTD_DIR!\Desktop\" /E /Z /MT:2 /R:3 /W:5 /XO /LOG+:"%LOGFILE%" 2>nul
        set "RC_BASE=%ERRORLEVEL%"
        echo Intento de copia escritorio base completado (código: !RC_BASE!) >> "%LOGFILE%"
    )

    REM Copiar escritorio específico según tipo
    set "DESKTOP_SOURCE="
    if /i "!TipoPC!"=="Envios" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Envios"
    if /i "!TipoPC!"=="Medico" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Medico"
    if /i "!TipoPC!"=="Comanda" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_Comanda"
    if /i "!TipoPC!"=="BTV" set "DESKTOP_SOURCE=\\!ServerIP!\SVI$\Desktop_BTV"

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

REM ============ LIMPIAR CONEXIONES TEMPORALES ==========
net use \\!ServerIP!\SVI$ /delete >nul 2>&1

echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
echo.
echo Proceso completado. Presiona cualquier tecla para continuar...
pause >nul
endlocal
exit /b 0