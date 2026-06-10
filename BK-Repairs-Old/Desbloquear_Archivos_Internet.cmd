@echo off
:: Desbloquea archivos provenientes de otros equipos o de internet que se encuentren en la misma carpeta 
:: y subcarpetas desde donde esta este Script. Esto evita que salten mensajes de SmartScreen
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath (Get-Location) -Recurse -Force | Unblock-File"
exit