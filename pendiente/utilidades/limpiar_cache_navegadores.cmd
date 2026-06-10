@echo off
title Limpiador de Historial, Cookies y Cache - Edge, Chrome y Firefox
echo ================================================
echo  CERRANDO PROCESOS DE NAVEGADORES...
echo ================================================
taskkill /IM msedge.exe /F >nul 2>&1
taskkill /IM chrome.exe /F >nul 2>&1
taskkill /IM firefox.exe /F >nul 2>&1

echo ================================================
echo  LIMPIANDO EDGE (Chromium)...
echo ================================================
set "edgePath=%LOCALAPPDATA%\Microsoft\Edge\User Data"
if exist "%edgePath%" (
    for /d %%d in ("%edgePath%\*") do (
        del /q "%%d\History*" 2>nul
        del /q "%%d\Cookies*" 2>nul
        del /q "%%d\Login Data*" 2>nul
        del /q "%%d\Web Data*" 2>nul
        rmdir /s /q "%%d\Cache" 2>nul
        rmdir /s /q "%%d\Code Cache" 2>nul
        rmdir /s /q "%%d\GPUCache" 2>nul
    )
    echo Edge limpiado correctamente.
) else (
    echo Edge no encontrado.
)

echo ================================================
echo  LIMPIANDO CHROME...
echo ================================================
set "chromePath=%LOCALAPPDATA%\Google\Chrome\User Data"
if exist "%chromePath%" (
    for /d %%d in ("%chromePath%\*") do (
        del /q "%%d\History*" 2>nul
        del /q "%%d\Cookies*" 2>nul
        del /q "%%d\Login Data*" 2>nul
        del /q "%%d\Web Data*" 2>nul
        rmdir /s /q "%%d\Cache" 2>nul
        rmdir /s /q "%%d\Code Cache" 2>nul
        rmdir /s /q "%%d\GPUCache" 2>nul
    )
    echo Chrome limpiado correctamente.
) else (
    echo Chrome no encontrado.
)

echo ================================================
echo  LIMPIANDO FIREFOX...
echo ================================================
set "ffPath=%APPDATA%\Mozilla\Firefox\Profiles"
if exist "%ffPath%" (
    for /d %%d in ("%ffPath%\*") do (
        del /q "%%d\cookies.sqlite*" 2>nul
        del /q "%%d\places.sqlite*" 2>nul
        del /q "%%d\formhistory.sqlite*" 2>nul
        del /q "%%d\signons.sqlite*" 2>nul
        rmdir /s /q "%%d\cache2" 2>nul
    )
    echo Firefox limpiado correctamente.
) else (
    echo Firefox no encontrado.
)

echo ================================================
echo  PROCESO FINALIZADO
echo ================================================
timeout /T 5
exit
