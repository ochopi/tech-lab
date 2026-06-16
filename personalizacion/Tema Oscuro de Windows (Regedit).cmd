REM # ACTIVAR TEMA OSCURO EN WINDOWS DESDE REGEDIT

REM # El Tema Claro u Oscuro de Windows se guarda en la siguiente clave
REM # Basta abrir el regedit y desplazarse hasta ella
REM # Equipo\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize

REM # Ahi hay que cambiar estos 2 valores a 0 para que el sistema quede en modo oscuro
REM # SystemUsesLightTheme = 0
REM # AppsUseLightTheme = 0

REM # O se puede hacer por comando:
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f