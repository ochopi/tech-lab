# Guia Rapida de Instalacion de MeshCentral (Windows)

Esta guia muestra como instalar MeshCentral en Windows dentro de una carpeta fija (local) como por ejemplo `C:\MeshCentral`.


## 1. Descargar e Instalar NodeJS
Descargar NodeJS desde su sitio oficial: https://nodejs.org/en/download/current

Instalarlo desde una consola CMD con permisos de Administrador:
```
msiexec /i "C:\Users\Usuario\Downloads\node-v25.2.0-x64.msi"
```

<br>

## 2. Verificar la instalacion de NodeJS y NPM
Abrir CMD o PowerShell y ejecutar:
```
node -v
npm -v
```
Ambos deben devolver una version.


### Si PowerShell muestra error
> “No se puede cargar el archivo porque la ejecucion de scripts esta deshabilitada”

Ejecutar una de estas opciones:

```
# Habilitar la Ejecucion de Scripts solo en la ventana Powershell actual:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Habilitar la Ejecucion de Scripts permanentemente solo para el Usuario actual (Modo Recomendado)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Habilitar la Ejecucion de Scripts permanentemente solo para el usuario actual (Modo Bypass):
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass

# Habilitar la Ejecucion de Scripts permanentemente para todo el sistema (No Recomendado):
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass
```

Despues de esto, `npm -v` ya debe funcionar.

<br>

## 3. Instalar MeshCentral (Instalacion Local)
Crear una carpeta fija donde vivira MeshCentral como por ejemplo: `C:\MeshCentral`
Abrir una consola **como Administrador** y desplazarse hasta la carpeta de instalacion:

```
cd C:\MeshCentral
npm install meshcentral
```

Esto instalara MeshCentral dentro de `C:\MeshCentral\node_modules\`.

## Instalacion Offline:
El comando `npm install meshcentral` requiere acceso a internet.

Si la maquina donde vamos a instalar MeshCentral no cuenta con acceso a intener, debemos descargar un paquete comprimido para instalarlo de manera offline

### Descargar MeshCentral
- En una PC con acceso a internet, Descargar e Instalar NodeJS (ver paso 1)
- Una ves instalado, ejecutar 
    ```
    npm pack meshcentral 
    ```
    Eso genera un archivo .tgz con el paquete completo, sin compilar.
- Copiar ese .tgz al servidor oficial (el que no tiene internet) en la carpeta donde se desea instalar Ejemplo: `C:\MeshCentral\`.
- Desplazarse a la carpeta y ejecutar:
    ```
    cd C:\MeshCentral\
    npm install meshcentral-x.x.x.tgz --production
    ```
    Eso instala MeshCentral correctamente, con dependencias compiladas en ese servidor.

<br>

## 4. Iniciar MeshCentral manualmente
Una vez instalado MeshCentra, Ejecutar (desde la carpeta de instalacion `C:\MeshCentral`):

```
node node_modules/meshcentral
```

La primera ejecucion generara la carpeta: `C:\MeshCentral\meshcentral-data` y pedira crear el primer usuario en el navegador.

### > Nota: El *primer usuario* creado sera Administrador.
Abrir (si es que el comando no lo abrio ya automaticamente):
https://localhost:4433  o  http://localhost:80/


<br>


## 5. Instalar MeshCentral como servicio de Windows
Para que MeshCentral inicie automaticamente cada vez que se inicie el equipo hayq ue instalarlo como servicio:
```
node node_modules/meshcentral --install
```

Y si deseamos Desinstalar el servicio:
```
node node_modules/meshcentral --uninstall
```

<br>

## 6. Archivo principal de configuracion: `config.json`
El archivo principal de configuracion de MeshCentral se encuentra en: `C:\MeshCentral\meshcentral-data\config.json`

Despues de la **primera ejecucion** ya existe y puede editarse.

## > Configuraciones basicas recomendadas

### Nombre de dominio o URL de conexion (`cert`)
Ejemplo: `cert": "mesh.miempresa.com"`
Esto determina la URL que veran los agentes y navegadores.

### Modo de operacion (LAN / WAN)
- **WAN only**: Para acceso desde internet  
- **LAN only**: Solo para uso dentro de la red local
En Settings:
```
"wanonly": true

o

"lanonly": true
```

### Autenticacion con LDAP/LDAPS (Active Directory)
Permite que usuarios del dominio inicien sesion.

Dentro de la seccion `auth` editamos:

```
"auth": {
    "ldap": {
        "server": "ldap://dc01.tudominio.local",
        "basedn": "DC=tudominio,DC=local",
        "usernamefield": "sAMAccountName"
    }
}
```


## 7. Puertos utilizados (rapido)
- **80** → HTTP / redireccion  
- **4433** → HTTPS inicial  
- **443** → HTTPS principal (si esta disponible)

Si usas dominio publico, abrir **443** en firewall.


## 8. Instalacion de "agentes" en las maquinas cliente
Una vez que hayamos iniciado sesion de MeshCentral por primera vez, nos pedira crear un "Grupo de Dispositivos"
Dentro del cual podremos comenzar a agregar "Agentes".

En esa seccion podemos Descargar el instalador correspondiente (Multiplataforma):
- Windows (x86/x64)
- Linux
- MacOS

Cuando se genera un instalado desde el servidor, este ya posee toda la informacion de conexion y certificados hacia este servidor, por lo cual, al instalarlo en una maquina cliente, esta automaticamente se comunica con el servidor y queda agregada bajo el grupo en el cual se creo el instalador (pero se puede mover de grupo despues, si se desea).

A estas maquinas clientes ya registradas se les llama **"agentes"**

Si se cambia una configuracion de conexion importante en el servidor, como lo es la url de conexion (`cert:`) o el certificado, se deben generar instaladores nuevos para que posean esta informacion actualizada.

### Nota: Cambiar la configuracion de conexion en el servidor puede hacer que los agentes con la configuracion de conexion anterior sean incapaces de conectarse a la nueva direccion. 
Tomar todas las medidas necesarias para evitar fallos.


## **NOTA IMPORTANTE: Respaldos recomendados**
La carpeta: `C:\MeshCentral\meshcentral-data` contiene toda la informacion esencial para el funcionamiento del serviro MeshCentral

Ahi se encuentran:
- Todas las Configuraciones
- Credenciales de Autenticacion
- Informacion de Usuarios
- Dispositivos
- Base de datos
- Certificados

Con esto puedes restaurar un servidor completo. Asi que se recomienda tener un respaldo de dicha carpeta en una ubicacion segura.