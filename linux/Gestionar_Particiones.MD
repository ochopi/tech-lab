# MONTAR PARTICIONES AUTOMATICAMENTE (Bazzite)
Si una particion no se monta automaticamente, o pide contraseña admin despues de cada reinicio, se puede hacer lo siguiente.

## PASO 1: IDENTIFICAR LA PARTICION DESEADA
```
sudo lsblk -f
```
Este comando nos devuelve todas las particiones, su UUID y punto de montaje.
Se supone que nuestra particion no debe estar montada.
De aqui unicamente copiamos el UUID de nuestra particion, por ejemplo: 01DC77A0084B5660


## PASO 2: CREAR PUNTO DE MONTAJE
Debemos crear una carpeta donde se montara esa particion
```
sudo mkdir /mnt/C_Windows
```


## PASO 3: EDITAR /etc/fstab
Ir a /etc/fstab y editar el archivo con un editor de texto o con nano
```
sudo nano /etc/fstab
```

Al final del archivo, crear una nueva linea.
```
UUID=01DC77A0084B5660  /mnt/C_Windows  ntfs3  rw,uid=1000,gid=1000,noatime,windows_names,nofail,x-systemd.device-timeout=5s  0  0
```
el UUID Debe ser el que encontramos con el PASO 1
/mnt/C_Windows debe ser la carpeta que creamos en el PASO 2


## PASO 4: GUARDAR y REINICIAR
Guardamos los cambios realizados en /etc/fstab
Reiniciamos el daemon y montamos todo de nuevo:
```
sudo systemctl daemon-reload
sudo mount -a
```

<br /><br />

# ERRORES FRECUENTES

# A) Partición “sucia” que se abre en modo "Read Only" (ro) aun cuando se especifico modo "rw"
### Script Relacionado:
OneDrive/Scripts/Linux_Scripts/Reparar_Particion_NTFS/ntfs-repair-and-remount.sh

A veces una partición NTFS no se monta correctamente porque Windows la dejó en uso o marcada como *dirty* (estado inconsistente).

Esto puede ocurrir por varias razones:

* Windows fue hibernado.
* El inicio rápido de Windows estaba activado.
* Un apagado incorrecto, cuelgue o reinicio forzado.
* Simplemente Windows siendo Windows.

En estos casos, Linux suele montar la partición en **solo lectura (ro)** por seguridad, aunque los permisos aparenten ser correctos.

---

## CHKDSK desde Linux (ntfsfix)

Para solventar esto, lo más “correcto” es volver a Windows y ejecutar un **CHKDSK** o permitir que Windows repare la unidad.

Si no queremos volver a Windows solo para eso, podemos hacer un “mini chkdsk” desde Linux usando `ntfsfix`.

**OJO. No es equivalente a CHKDSK**, pero puede:

* limpiar el flag *dirty*
* vaciar el journal NTFS
* dejar el volumen en un estado consistente mínimo

Ejemplo:

```
sudo ntfsfix /dev/nvme0n1p4
```

Reemplaza `nvme0n1p4` por la partición correcta.
Puedes identificarla con:

```
lsblk -f
```

o, si ya está montada:

```
findmnt
```

---

Luego de eso, desmontamos y volvemos a montar la partición:

```
sudo umount /var/mnt/D_Midgard
sudo mount -a
```

En este caso `mount -a` funciona porque previamente ya habíamos agregado y especificado `D_Midgard` en el archivo `/etc/fstab`.
Si no fuera así, podemos montar manualmente con:

```
sudo mount -t ntfs-3g /dev/nvme0n1p4 /var/mnt/D_Midgard
```

(reemplazando dispositivo y punto de montaje según corresponda).

---

## PARTCIÓN EN USO o “BUSY”

En algunos casos, al intentar desmontar una partición, el sistema indica que está *busy* (en uso).

Para averiguar qué proceso la está usando y poder liberarla, podemos usar:

```
sudo lsof +f -- /var/mnt/D_Midgard
```

Reemplaza `D_Midgard` por el punto de montaje en cuestión.
Esto mostrará los procesos que mantienen archivos abiertos en esa partición.

Alternativa más directa:

```
sudo fuser -vm /var/mnt/D_Midgard
```

A partir de ahí, podemos cerrar aplicaciones o, si es necesario, terminar procesos manualmente.

Para matar un proceso concreto:

```
sudo kill PID
```

o, si no responde:

```
sudo kill -9 PID
```

(donde `PID` es el identificador del proceso).

⚠️ Nota breve: evita usar `kill -9` a la ligera; no permite limpieza y puede provocar más problemas si se abusa.

---

Una vez liberada la partición, ya podremos desmontar y volver a montar:

```
sudo umount /var/mnt/D_Midgard
sudo mount -a
```
---
### Script Relacionado:
OneDrive/Scripts/Linux_Scripts/Reparar_Particion_NTFS/ntfs-repair-and-remount.sh

<br /><br />


# B) Despues de reparticionar, Bazzite da error.
Si por alguna razon, en el paso 3 editamos el `/etc/fstab` y agregamos `UUID` para montar particiones automaticamente
Y no usamos el parametro `nofail` Bazzite pordia entrar en "Modo Emergencia" y no dejarnos iniciar.
Esto pasa cuando reparticionamos desde Windows. Los UUID pueden cambiar.

Por eso es importante usar los parametros `nofail,x-systemd.device-timeout=5s`
```
UUID=01DC77A0084B5660  /mnt/C_Windows  ntfs3  rw,uid=1000,gid=1000,noatime,windows_names,nofail,x-systemd.device-timeout=5s  0  0
```
En caso de que ya no nos deje iniciar, deberemos ingresar con un LiveOS que nos permita acceso a terminal (Bazzite Live no sirve para este proposito).

- ## REPARANDO `/etc/fstab` DEFECTUOSO
Para recuperar acceso a nuestro sistema operativo, debemos ingresar con un LiveOS (desde una USB o similar) puede ser Ubuntu Live.
Comprobamos las particiones y sus UUID con `sudo lsblk -f`

**(Nota, Para Bazzite y sistemas inmutables, el montaje es un poco diferente, se explica mas adelante)**

Identificamos la particion de nuestro sistema Linux, por ejemplo `nvme0n1p6` y la montamos con:
```
sudo mount /dev/nvme0n1p6 /mnt
```
Luego abrimos `/mnt` y buscamos nuestro archivo `fstab` para editarlo
```
sudo nano /mnt/etc/fstab
```
* Corregimos los UUID por los correctos segun nos muestre `sudo lsblk -f`
* Agregamos los parametros de seguridad `nofail,x-systemd.device-timeout=5s`
* Guardamos `(Ctrl+O)` y Salimos `(Ctrl+X)`
* Volvemos a abrir `sudo nano /mnt/etc/fstab` solo para comprobar que los cambios se hayan realizado. Y de ser afirmativo, ya podriamos reiniciar normalmente.

**OJO: Si estamos en un sistema inmutable como Bazzite, los pasos son los siguientes:**
Identificamos la particion de nuestro sistema Linux, por ejemplo `nvme0n1p6` y la montamos con:
```
sudo mount /dev/nvme0n1p6 /mnt
```
Luego listamos los subvolumenes que hay dentro con
```
sudo btrfs subvolume list /mnt
```
Deberiamos ver algo como 
* root
* var
* home

Desmontamos la particion:
```
sudo umount /mnt
```
Luego montamos el subvolumen correcto:
```
sudo mount -o subvol=root /dev/nvme0n1p6 /mnt
```
Si no existe root, prueba:
```
sudo mount -o subvol=@ /dev/nvme0n1p6 /mnt
```
O, muy tipico en rpm-ostree:
```
sudo mount -o subvol=ostree/deploy/bazzite/deploy/*/root /dev/nvme0n1p6 /mnt
```

Usando el explorador de archivos por ejemplo puedes encontrar que el `fstab` se puede encontrar dentro de:
```
/mnt/ostree/boot.0/default/5dad4......7a8/0/etc/fstab
```
Debemos tener en cuenta que en sistemas inmutables, se guardan varias copias o **"DEPLOYS"** por lo que deberiamos editarlas todas, o editar la mas reciente y luego hacer un `cleanup`

cada deploy tiene una carpeta diferente dentro de `/mnt/ostree/` como `boot.0`, `boot.1`, etc.

Una vez localizado el o los `fstab` necesarios, procedemos a editarlos con:
```
sudo nano /mnt/ostree/boot.1/default/5dad4……7a8/0/etc/fstab
```
* Corregimos los UUID por los correctos segun nos muestre `sudo lsblk -f`
* Agregamos los parametros de seguridad `nofail,x-systemd.device-timeout=5s`
* o simplemente Comentamos las lineas si lo que deseamos en ingresar a nuestro sistema sin preocuparnos de montar otras particiones. (Eso se puede revisar a posterior, ya con el sistema estable)
* Guardamos `(Ctrl+O)` y Salimos `(Ctrl+X)`
* Volvemos a abrir `sudo nano /mnt/etc/fstab` solo para comprobar que los cambios se hayan realizado. Y de ser afirmativo, ya podriamos reiniciar normalmente.

<BR /><BR />

# C) DESPUES DE UN ERROR, BAZZITE NOS MUESTRA EL GRUB CON VARIOS OSTREE

Como dijimos en la seccion anterior, Bazzite y sistemas inmutables pueden guardar 2 o mas deployments en su interior, por lo que corregir un unico `fstab` o un error en general en uno solo de los deployments puede no ser suficiente para recuperar la estabilidad total del sistema.

Por ejemplo, si corregimos el `fstab` de `boot.1` pero no el de `boot.0`
Y el sistema por defecto intenta arrancar desde el deplyment `boot.0` entonces nos seguira dando error. O nos mostrara el GRUB con las entradas `ostree 0`. `ostree 1`.
Si logramos ingresar al `ostree 1` (el que corregimos el `fstab`) podemos hacer desde dentro un `cleanup`.

Primero conviene hacer un `rpm-ostree status` el cual nos mostrara cuantos deployments tenemos.
Nos mostrara cual es el activo y cual esta "dañado"

Si ya estamos dentro de Bazzite significa que hay por lo menos 1 deployment activo y funcionando, y desde él podemos hacer un `sudo rpm-ostree cleanup -p` el cual limpiará los demas deployments "corruptos" y nos dejara unicamente con el que tenemos activo.

Despues de ejecutar el `sudo rpm-ostree cleanup -p` podemos volver a correr `rpm-ostree status` para comprobar que ya solo tenemos 1 deployment activo. Eso evitará que se siga mostrando la ventana de GRUB y nos permitira ingresar directamente a Bazzite, desde el cual podremos, si lo deseamos, volver a hacer upgrade hacia el deployment mas reciente.

**Para actualizar al Deployment mas reciente ejecutamos:**
```
sudo rpm-ostree upgrade
```
Cuando termine de actualizar, reiniciamos y ya tendriamos nuestro sistema recuperado y actualizado.

Si volvemos a ejecutar un `rpm-ostree status` veremos que, de nuevo, tenemos 2 Deployments. 1 previo a la actualizacion y otro con el sistema actualizado.
Es decir, el deployment actual y el deployment anterior (fallback).

Conviene dejarlo asi pues, si se rompe nuestro deployment actual, tendremos el anterior al cual volver.