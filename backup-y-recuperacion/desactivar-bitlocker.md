# Desactivar Bitlocker

Algunas veces aparece el simbolo de Bitlocker en el Disco Local C, ya sea abierto o cerrado.
Eso significa que al menos parte de Bitlocker esta activo.

## Comprobar el estado de BitLocker

En una ventana de Powershell con permisos de Administrador:

```bash
manage-bde -status 
```

Nos devolvera algo como lo siguiente:

```bash
PS C:\WINDOWS\system32> manage-bde -status 

Cifrado de unidad BitLocker: versión de la herramienta de configuración 10.0.26100 
Copyright (C) 2013 Microsoft Corporation. Todos los derechos reservados. 
Volúmenes del disco que se pueden proteger con el Cifrado de unidad 
BitLocker: 
Volumen C: [] [Volumen del sistema operativo] 
Tamaño: 237.57 GB 
Versión de BitLocker: 2.0 
Estado de conversión: Cifrado solo de espacio usado 
Porcentaje cifrado: 100.0% 
Método de cifrado: XTS-AES 128 
Estado de protección: Protección desactivada 
Estado de bloqueo: Desbloqueado 
Campo de identificación:Desconocido 
Protectores de clave: ninguno 
```

En este caso en especifico podemos ver que a pesar de que el `Estado de proteccion` es `Proteccion desactivada`

Pero el `Porcentaje de cifrado` es del 100% y el `"Estado de conversión: Cifrado solo de espacio usado."`



## Desactiva BitLocker

Si lo que deseamos es desactivar por completo BitLocker usaremos el siguiente comando:

```bash
manage-bde -off C: 
```

> Siendo "C:" la letra de la unidad que deseamos desbloquear.



Acto seguido podemos correr un  `manage-bde -status C:`  que nos dirá el estado actual del disco. 

Ahi podremos ver cómo el "Porcentaje de cifrado" comienza a bajar hasta llegar a 0% (Puede tomar varios minutos).



Una vez transcurrido un tiempo podemos volver a hacer un  `manage-bde -status C:`  y deberiamos ver 
`Estado de conversión: Descifrado completo`

```bash
PS C:\WINDOWS\system32> manage-bde -status 

Cifrado de unidad BitLocker: versión de la herramienta de configuración 10.0.26100 
Copyright (C) 2013 Microsoft Corporation. Todos los derechos reservados. 
Volúmenes del disco que se pueden proteger con el Cifrado de unidad BitLocker: 
Volumen C: [] 
[Volumen del sistema operativo] 
Tamaño: 237.57 GB 
Versión de BitLocker: Ninguno 
Estado de conversión: Descifrado completo 
Porcentaje cifrado: 0.0% 
Método de cifrado: Ninguno 
Estado de protección: Protección desactivada 
Estado de bloqueo: Desbloqueado 
Campo de identificación:Ninguno 
Protectores de clave: ninguno 
```

Asi quedaria deshabilitado BitLocker, evitando problemas futuros si se daña el disco.