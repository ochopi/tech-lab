@echo off
echo Aplicando configuraciones desatendidas... 
setlocal
set XML=%~dp0autounattend.xml
if not exist "%WINDIR%\Panther" mkdir "%WINDIR%\Panther"
copy /Y "%XML%" "%WINDIR%\Panther\unattend.xml" >nul
timeout /t 3 >nul
%WINDIR%\System32\Sysprep\Sysprep.exe /oobe /unattend:%XML% /reboot
exit