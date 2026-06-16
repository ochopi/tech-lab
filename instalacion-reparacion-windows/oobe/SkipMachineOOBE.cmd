@echo off
REM PASO #1 NET USER
REM Crear nuestro usuario
net user soportecnico 12345678 /add
net localgroup administrators soportecnico /add
net localgroup administradores soportecnico /add
net user soportecnico /active:yes
net user soportecnico /expires:never

net user Administrator /active:no
net user Administrador /active:no
net user defaultUser0 /delete


REM PASO #2 REGEDIT
REM reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v DefaultAccountSAMName
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v DefaultAccountAction /f
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v DefaultAccountSAMName /f
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v DefaultAccountSID /f
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v LaunchUserOOBE /f

REM reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v SkipMachineOOBE /t REG_DWORD /d 1 /f

shutdown /r /f /t 0





REM PASO #2 REGEDIT via GUI
REM Este paso puede hacerlo Por GUI si lo desea

REM regedit

REM Navegar hasta HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE
REM Borrar todas las claves que hay ahi menos la (Default)

REM BORRAR DefaultAccountAction
REM BORRAR DefaultAccountSAMName
REM BORRAR DefaultAccountSID
REM BORRAR LaunchUserOOBE

REM Crear una clave llamada SkipMachineOOBE DWORD32 Con valor 1

