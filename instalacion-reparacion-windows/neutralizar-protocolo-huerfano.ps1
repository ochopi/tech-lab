# Script: Neutralizar protocolo huérfano en Windows
# Uso: Ejecutar en PowerShell como administrador
# Pedirá el nombre del protocolo (ej: ms-gamebar) y creará el handler vacío.

# Solicitar protocolo
$protocol = Read-Host "Introduce el nombre del protocolo huérfano (sin '://')"

if ([string]::IsNullOrWhiteSpace($protocol)) {
    Write-Host "No se introdujo un protocolo. Saliendo..."
    exit
}

$path = "HKCR\$protocol"
$commandKey = "HKCR\$protocol\shell\open\command"
$urlAssocKey = "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$protocol"
$systrayPath = "`"$env:SystemRoot\System32\systray.exe`""


Write-Host "Creando handler dummy para protocolo: $protocol" -ForegroundColor Yellow

# Crear claves base
reg add $path /f /ve /d "URL:$protocol" 2>&1 > $null
reg add $path /f /v "URL Protocol" /d "" 2>&1 > $null
reg add $path /f /v "NoOpenWith" /d "" 2>&1 > $null

# Crear estructura en HKCR\<protocolo>\shell\open\command
reg add $commandKey /f /ve /d $systrayPath > $null 2>&1

# Crear clave vacía en HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\<protocolo>
if (-not (Test-Path $urlAssocKey)) {
    New-Item -Path $urlAssocKey -Force | Out-Null
}

Write-Host "Protocolo '$protocol' neutralizado. Reinicia o vuelve a probar el evento." -ForegroundColor Green
