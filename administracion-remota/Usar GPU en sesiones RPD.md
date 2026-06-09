# Usar GPU en sesiones RDP

## Problema:

El equipo cuenta con una GPU dedicada (Nvidia GeForce GT 710) la cual entra en uso al estar fisicamente frente a la PC, usando los 2 monitores, conectados fisicamente a esa GPU.

Pero al conectarse remotamente por RDP, la sesion usa CPU.

Lo cual normalmente no seria un inconveniente pero si, por ejemplo, como yo, se tiene un Live Wallpaper activo, eso representa una enorme carga para el CPU (un i7-6700 @ 3.40GHz)

## Solución:

Abrir el `Editor de directivas de grupo local`, dentro de `"Directiva del Equipo Local"` Navegar y habilitar estas 2 opciones:

```bash
Computer Configuration
 └ Administrative Templates
    └ Windows Components
       └ Remote Desktop Services
          └ Remote Desktop Session Host
             └ Remote Session Environment
                └ Use hardware graphics adapters for all Remote Desktop Services sessions
                └ Configure H.264/AVC hardware encodign for Remote Desktop Connections
```

o  en español...

```bash
Configuracion del Equipo
 └ Plantillas Administrativas
    └ Componentes de Windows
       └ Servicios de Escritorio Remoto
          └ Host de sesion de Escritorio Remoto
             └ Entorno de sesion remota
                └ Usar tarjetas graficas de hardware para todas las sesiones de Servicios de Escritorio Remoto
                └ Configurar codificacion de hardware H.264/AVC para las Conexiones de Escritorio Remoto
```

Luego ejecutar

```bash
gpupdate /force
```

y reiniciar