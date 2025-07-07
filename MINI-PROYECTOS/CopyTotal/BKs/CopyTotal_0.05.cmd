@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ==================== CONFIG ====================
set "SCRIPT_ROOT=C:\SHR8\CopyTotal"
set "LOGFILE=%SCRIPT_ROOT%\copy2log.log"
set "FALLBACK_SUBNET=10.10.2"
set "DEFAULT_SERVER1=%FALLBACK_SUBNET%.61"
set "DEFAULT_SERVER2=%FALLBACK_SUBNET%.31"

REM Credenciales de dominio de último recurso
set "USERDEF=usuario_generico"
set "PASSDEF=password_generico"

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

REM Si no se detectó IP, usar fallback
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

REM ============ DETECTAR CONTEXTO DE EJECUCIÓN ==========
set "IS_DOMAIN_USER=false"
set "CURRENT_USER="

REM Obtener usuario actual
for /f "tokens=*" %%a in ('whoami') do set "CURRENT_USER=%%a"
echo Usuario actual: !CURRENT_USER! >> "%LOGFILE%"

REM Verificar si es usuario de dominio (contiene \)
echo !CURRENT_USER! | findstr /i "\" >nul 2>&1
if not errorlevel 1 (
    echo !CURRENT_USER! | findstr /i "!HOSTNAME!" >nul 2>&1
    if errorlevel 1 (
        set "IS_DOMAIN_USER=true"
        echo Contexto: Usuario de dominio detectado >> "%LOGFILE%"
    ) else (
        echo Contexto: Usuario local detectado >> "%LOGFILE%"
    )
) else (
    echo Contexto: Usuario local detectado >> "%LOGFILE%"
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

REM Probar Server61 primero
call :ping_multiple "!Server61!"
if "!PING_SUCCESS!"=="true" (
    set "ServerIP=!Server61!"
    echo Servidor !Server61! seleccionado >> "%LOGFILE%"
)

REM Si no funcionó, probar Server31
if not defined ServerIP (
    call :ping_multiple "!Server31!"
    if "!PING_SUCCESS!"=="true" (
        set "ServerIP=!Server31!"
        echo Servidor !Server31! seleccionado >> "%LOGFILE%"
    )
)

REM Si no funcionó con la subred detectada, intentar con servidores default
if not defined ServerIP (
    echo Probando con servidores default... >> "%LOGFILE%"
    call :ping_multiple "%DEFAULT_SERVER1%"
    if "!PING_SUCCESS!"=="true" (
        set "ServerIP=%DEFAULT_SERVER1%"
        echo Servidor default %DEFAULT_SERVER1% seleccionado >> "%LOGFILE%"
    )
)

if not defined ServerIP (
    call :ping_multiple "%DEFAULT_SERVER2%"
    if "!PING_SUCCESS!"=="true" (
        set "ServerIP=%DEFAULT_SERVER2%"
        echo Servidor default %DEFAULT_SERVER2% seleccionado >> "%LOGFILE%"
    )
)

if not defined ServerIP (
    echo ERROR: Ningún servidor disponible via ping. Abortando. >> "%LOGFILE%"
    echo Detalles de diagnóstico: >> "%LOGFILE%"
    echo - Subred detectada: !Subnet! >> "%LOGFILE%"
    echo - Servidores probados: !Server61!, !Server31!, %DEFAULT_SERVER1%, %DEFAULT_SERVER2% >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    exit /b 1
)

echo Servidor seleccionado: !ServerIP! >> "%LOGFILE%"

REM ============ AUTENTICACIÓN INTELIGENTE ==========
set "AUTH_SUCCESS=false"
set "MAPPED_DRIVE=false"

echo Iniciando proceso de autenticación... >> "%LOGFILE%"

REM Método 1: Si es usuario de dominio, acceso directo
if "!IS_DOMAIN_USER!"=="true" (
    echo Método 1: Acceso directo como usuario de dominio >> "%LOGFILE%"
    if exist "\\!ServerIP!\SVI$\SHR8" (
        echo Acceso directo exitoso >> "%LOGFILE%"
        set "AUTH_SUCCESS=true"
    ) else (
        echo Acceso directo falló >> "%LOGFILE%"
    )
)

REM Método 2: Intentar con credenciales almacenadas
if "!AUTH_SUCCESS!"=="false" (
    echo Método 2: Probando credenciales almacenadas >> "%LOGFILE%"
    cmdkey /list:"!ServerIP!" >nul 2>&1
    if not errorlevel 1 (
        echo Credenciales encontradas para !ServerIP! >> "%LOGFILE%"
        net use \\!ServerIP!\SVI$ /persistent:no >nul 2>&1
        if exist "\\!ServerIP!\SVI$\SHR8" (
            echo Acceso con credenciales almacenadas exitoso >> "%LOGFILE%"
            set "AUTH_SUCCESS=true"
            set "MAPPED_DRIVE=true"
        ) else (
            echo Acceso con credenciales almacenadas falló >> "%LOGFILE%"
        )
    ) else (
        echo No hay credenciales almacenadas para !ServerIP! >> "%LOGFILE%"
    )
)

REM Método 3: Intentar con usuario estándar detectado
if "!AUTH_SUCCESS!"=="false" (
    if defined USERSTD (
        echo Método 3: Probando mapeo con usuario estándar detectado >> "%LOGFILE%"
        net use \\!ServerIP!\SVI$ /user:!USERSTD! /persistent:no >nul 2>&1
        if exist "\\!ServerIP!\SVI$\SHR8" (
            echo Acceso con usuario estándar exitoso >> "%LOGFILE%"
            set "AUTH_SUCCESS=true"
            set "MAPPED_DRIVE=true"
            REM Guardar credenciales para próximas ejecuciones
            cmdkey /add:"!ServerIP!" /user:"!USERSTD!" >nul 2>&1
        ) else (
            echo Acceso con usuario estándar falló >> "%LOGFILE%"
        )
    )
)

REM Método 4: Último recurso - Usuario genérico
if "!AUTH_SUCCESS!"=="false" (
    echo Método 4: Último recurso - Usuario genérico de dominio >> "%LOGFILE%"
    net use \\!ServerIP!\SVI$ /user:!USERDEF! !PASSDEF! /persistent:no >nul 2>&1
    if exist "\\!ServerIP!\SVI$\SHR8" (
        echo Acceso con usuario genérico exitoso >> "%LOGFILE%"
        set "AUTH_SUCCESS=true"
        set "MAPPED_DRIVE=true"
        REM Guardar credenciales para próximas ejecuciones
        cmdkey /add:"!ServerIP!" /user:"!USERDEF!" /pass:"!PASSDEF!" >nul 2>&1
    ) else (
        echo Acceso con usuario genérico falló >> "%LOGFILE%"
    )
)

if "!AUTH_SUCCESS!"=="false" (
    echo ERROR CRÍTICO: No se pudo autenticar contra el servidor >> "%LOGFILE%"
    echo Métodos probados: >> "%LOGFILE%"
    echo - Acceso directo (usuario de dominio): !IS_DOMAIN_USER! >> "%LOGFILE%"
    echo - Credenciales almacenadas: Probado >> "%LOGFILE%"
    echo - Usuario estándar: !USERSTD! >> "%LOGFILE%"
    echo - Usuario genérico: !USERDEF! >> "%LOGFILE%"
    echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
    exit /b 2
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
    echo - Problemas de permisos >> "%LOGFILE%"
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
if "!MAPPED_DRIVE!"=="true" (
    echo Limpiando conexiones temporales... >> "%LOGFILE%"
    net use \\!ServerIP!\SVI$ /delete >nul 2>&1
)

echo FIN: %DATE% - %TIME% >> "%LOGFILE%"
echo Proceso completado exitosamente.
endlocal
exit /b 0